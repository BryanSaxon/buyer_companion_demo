class DesignFlow
  attr_reader :session, :lead

  def initialize(session:, lead:)
    @session = session
    @lead    = lead
    @llm     = CompanionLlm.new
  end

  # Called by MessagesController for free-text input.
  # Returns { message:, component_html:, component_type:, state:, rooms_complete:, total_rooms: }
  def handle_text(user_input)
    state_ctx = state_context_description
    history   = lead.chat_messages.chronological.last(10)

    llm_result = @llm.call(
      session: session, lead: lead,
      user_input: user_input,
      state_context: state_ctx,
      history: history
    )

    if llm_result["is_off_topic"]
      return handle_off_topic(user_input, llm_result)
    end

    advance_if_ready(llm_result)
  end

  # Called by SelectionsController for structured component interactions.
  # action_data: { type:, ...payload }
  def handle_selection(action_data)
    case action_data[:type]
    when "room_purpose"  then handle_room_purpose(action_data)
    when "occupants"     then handle_occupants(action_data)
    when "design_styles" then handle_design_styles(action_data)
    when "option"        then handle_option(action_data)
    when "pending"       then handle_pending_selection(action_data)
    when "progress_next" then handle_progress_next
    when "summary_edit"          then handle_summary_edit(action_data)
    when "summary_done"          then handle_summary_done
    when "summary_change_intent" then handle_summary_change_intent
    when "welcome_ready"         then handle_welcome_ready
    when "welcome_info"          then handle_welcome_info
    else
      { message: "Something went wrong — let's try that again.", component_html: nil }
    end
  end

  # Auto-generates the welcome message for new sessions
  def welcome_message
    "Hi Chris and Cindy! Welcome to your design journey with #{lead.org_name}. " \
    "I'm your personal home companion, and I'll be with you every step of the way as " \
    "you plan your beautiful new home at Crystal Ridge. We have your Brookfield floor plan " \
    "all set — 3 bedrooms, 2 bathrooms, plus a flex room you get to design exactly how you want. " \
    "Ready to start planning together?"
  end

  def welcome_component_html
    render_component("chat_components/welcome_prompt", session: session)
  end

  private

  # --- State handlers ---

  def handle_welcome_ready
    session.begin_planning!
    plan_first_room
  end

  def handle_welcome_info
    msg = "Of course! Here's how it works: we'll start by mapping out every room — " \
          "who's sleeping where, what you'll use your flex room for. Then we'll get a sense " \
          "of your design style. After that, we'll go room by room picking finishes: flooring, " \
          "wall colors, tile, hardware — all of it. At the end, you'll have a complete design " \
          "brief ready for your meeting with Megan. It usually takes about 15–20 minutes, and " \
          "you can pause and come back any time. Ready?"
    { message: msg, component_html: render_component("chat_components/welcome_prompt", session: session, show_info_btn: false),
      component_type: "welcome_prompt", state: session.aasm_state, rooms_complete: 0, total_rooms: 8 }
  end

  def handle_off_topic(user_input, llm_result)
    subject = llm_result["draft_email_subject"] || "Question from the Morgan family"
    body    = llm_result["draft_email_body"] || generate_draft_body(user_input)

    draft = session.draft_emails.create!(
      original_question: user_input,
      subject: subject,
      body: body
    )

    { message: llm_result["message"],
      component_html: render_component("chat_components/email_draft", draft: draft),
      component_type: "email_draft",
      state: session.aasm_state,
      rooms_complete: session.rooms_complete_count,
      total_rooms: 8 }
  end

  def advance_if_ready(llm_result)
    # If the LLM flagged this as a conversational reply (can_advance: false),
    # don't re-render the selection component — let the chat breathe naturally.
    # The existing component is already visible; re-appending it feels robotic.
    conversational = llm_result["can_advance"] == false

    { message: llm_result["message"],
      component_html: conversational ? nil : next_component_html,
      component_type: conversational ? nil : next_component_type,
      state: session.aasm_state,
      rooms_complete: session.rooms_complete_count,
      total_rooms: 8 }
  end

  def plan_first_room
    next_room = session.next_unplanned_room
    if next_room.nil?
      session.finish_planning!
      session.save!
      return move_to_style_selection
    end
    session.update!(current_room: next_room[:key])
    msg = planning_intro_for(next_room)
    { message: msg,
      component_html: planning_component_for(next_room),
      component_type: planning_component_type_for(next_room),
      state: session.aasm_state,
      rooms_complete: 0,
      total_rooms: 8 }
  end

  def handle_room_purpose(data)
    room_key = data[:room_key]
    purpose  = data[:purpose]
    label    = data[:purpose_label]

    rp = session.room_plans.find_or_initialize_by(room_key: room_key)
    rp.purpose       = purpose
    rp.purpose_label = label
    rp.complete      = true
    rp.save!

    next_room = session.next_unplanned_room
    if next_room
      session.update!(current_room: next_room[:key])
      msg = planning_intro_for(next_room)
      { message: msg,
        component_html: planning_component_for(next_room),
        component_type: planning_component_type_for(next_room),
        state: session.aasm_state,
        rooms_complete: 0,
        total_rooms: 8 }
    else
      session.finish_planning!
      session.save!
      move_to_style_selection
    end
  end

  def handle_occupants(data)
    room_key  = data[:room_key]
    occupants = Array(data[:occupants])

    rp = session.room_plans.find_or_initialize_by(room_key: room_key)
    rp.occupants_array = occupants
    rp.purpose         = "bedroom"
    rp.complete        = true
    rp.save!

    next_room = session.next_unplanned_room
    if next_room
      session.update!(current_room: next_room[:key])
      msg = planning_intro_for(next_room)
      { message: msg,
        component_html: planning_component_for(next_room),
        component_type: planning_component_type_for(next_room),
        state: session.aasm_state,
        rooms_complete: 0,
        total_rooms: 8 }
    else
      session.finish_planning!
      session.save!
      move_to_style_selection
    end
  end

  def handle_design_styles(data)
    styles = Array(data[:styles])
    session.design_styles_array = styles
    session.finish_styles!
    session.save!

    first_room = DemoData::ROOMS.first
    session.update!(current_room: first_room[:key], current_selection_index: 0)

    msg = "Your taste is wonderful — those styles are going to translate beautifully " \
          "into your selections. Let's start designing your home, beginning with the " \
          "master bedroom. We'll go through each finish one by one."
    { message: msg,
      component_html: render_option_selector,
      component_type: "option_selector",
      state: session.aasm_state,
      rooms_complete: 0,
      total_rooms: 8 }
  end

  def handle_option(data)
    room_key       = data[:room_key]
    selection_type = data[:selection_type]
    option_key     = data[:option_key]
    option_label   = data[:option_label]

    session.design_selections.upsert(
      { design_session_id: session.id, room_key: room_key,
        selection_type: selection_type, option_key: option_key,
        option_label: option_label, pending: false,
        created_at: Time.current, updated_at: Time.current },
      unique_by: :idx_design_selections_unique
    )

    selections_for_room = DemoData.selections_for(room_key)
    next_idx            = session.current_selection_index + 1
    next_selection      = selections_for_room[next_idx]

    warm_message = selection_confirmation_llm_message(
      room_key: room_key,
      selection_type: selection_type,
      option_label: option_label,
      next_selection_label: next_selection&.dig(:label),
      is_last_in_room: next_selection.nil?
    )

    advance_design_cursor(warm_message)
  end

  def handle_pending_selection(data)
    room_key       = data[:room_key]
    selection_type = data[:selection_type]

    catalog = DemoData.selections_for(room_key).find { |s| s[:type] == selection_type }
    label   = catalog ? catalog[:label] : selection_type.humanize

    session.design_selections.upsert(
      { design_session_id: session.id, room_key: room_key,
        selection_type: selection_type, option_key: "pending",
        option_label: "#{label} — Not sure yet", pending: true,
        created_at: Time.current, updated_at: Time.current },
      unique_by: :idx_design_selections_unique
    )

    selections_for_room = DemoData.selections_for(room_key)
    next_idx            = session.current_selection_index + 1
    next_selection      = selections_for_room[next_idx]
    room                = DemoData.room(room_key)
    skip_msg = next_selection.nil? ?
      "That's totally okay — Megan will help you land on #{label.downcase} at your design meeting. Let's wrap up #{room[:label]}!" :
      "No worries at all — Megan will sort out #{label.downcase} with you at your meeting. Let's move on to #{next_selection[:label].downcase}."

    advance_design_cursor(skip_msg)
  end

  def handle_progress_next
    next_room = session.next_undesigned_room
    if next_room
      session.update!(current_room: next_room[:key], current_selection_index: 0)
      { message: "Let's design the #{next_room[:label]}!",
        component_html: render_option_selector,
        component_type: "option_selector",
        state: session.aasm_state,
        rooms_complete: session.rooms_complete_count,
        total_rooms: 8 }
    else
      session.finish_designing!
      session.save!
      move_to_summary
    end
  end

  def handle_summary_edit(data)
    room_key = data[:room_key]
    room     = DemoData.room(room_key)
    session.update!(current_room: room_key, current_selection_index: 0, aasm_state: "designing")
    session.save!

    { message: "Sure! Let's revisit the #{room[:label]}. I'll show your previous picks — just tap to change any you'd like.",
      component_html: render_option_selector,
      component_type: "option_selector",
      state: "designing",
      rooms_complete: session.rooms_complete_count,
      total_rooms: 8 }
  end

  def handle_summary_done
    session.finish_summary!
    session.save!
    date = DemoData.next_design_meeting_date
    msg  = "Chris and Cindy, your design selections are complete — and they are going to be stunning. " \
           "We can't wait to see you at your design meeting with Megan on #{date}. " \
           "She'll have everything laid out so you can see it all in person. " \
           "Thank you so much for planning your home with #{lead.org_name}!"
    { message: msg, component_html: nil, component_type: nil,
      state: "complete", rooms_complete: 8, total_rooms: 8 }
  end

  def advance_design_cursor(warm_message = nil)
    selections_for_room = DemoData.selections_for(session.current_room)
    next_idx = session.current_selection_index + 1

    if next_idx < selections_for_room.size
      session.update!(current_selection_index: next_idx)
      msg = warm_message || confirmation_message_for_selection
      { message: msg,
        component_html: render_option_selector,
        component_type: "option_selector",
        state: session.aasm_state,
        rooms_complete: session.rooms_complete_count,
        total_rooms: 8 }
    else
      room_label = DemoData.room(session.current_room)[:label]
      msg = warm_message || "#{room_label} is done! Great choices — these are going to look incredible together."
      { message: msg,
        component_html: render_component("chat_components/progress_card",
                                         session: session, room_key: session.current_room,
                                         rooms_complete: session.rooms_complete_count),
        component_type: "progress_card",
        state: session.aasm_state,
        rooms_complete: session.rooms_complete_count,
        total_rooms: 8 }
    end
  end

  def handle_summary_change_intent
    msg = "Of course — no problem at all! Tap 'Edit' next to any room below to revisit it. " \
          "You can change as many selections as you'd like."
    { message: msg,
      component_html: render_component("chat_components/summary_card", session: session),
      component_type: "summary_card",
      state: session.aasm_state,
      rooms_complete: session.rooms_complete_count,
      total_rooms: 8 }
  end

  def move_to_style_selection
    msg = "Perfect — we've mapped out every room. Now, before we start picking finishes, " \
          "let's find your style. Which of these feels most like home to you? " \
          "You can pick more than one."
    { message: msg,
      component_html: render_component("chat_components/style_picker", session: session),
      component_type: "style_picker",
      state: session.aasm_state,
      rooms_complete: 0,
      total_rooms: 8 }
  end

  def move_to_summary
    msg = "Here's everything you've put together for your home. These selections are going to be beautiful — " \
          "take a moment to review and let me know if anything needs adjusting."
    { message: msg,
      component_html: render_component("chat_components/summary_card", session: session),
      component_type: "summary_card",
      state: "summary_review",
      rooms_complete: 8,
      total_rooms: 8 }
  end

  # --- Planning helpers ---

  def planning_intro_for(room)
    case room[:type]
    when :bedroom
      if room[:ask_occupants]
        assigned = session.assigned_occupant_keys
        remaining = DemoData.unassigned_family(assigned)
        if remaining.empty?
          "#{room[:label]} — it looks like everyone's been assigned a room. " \
          "Would you like to designate this one as a guest room?"
        else
          "#{room[:label]} — who will be sleeping here?"
        end
      else
        "Great! #{room[:label]} is set for Chris and Cindy."
      end
    when :flex
      "Now for the flex room — this one is totally yours to design. " \
      "What are you thinking you'll use it for?"
    when :bathroom
      "#{room[:label]} — we'll design this one when we get to finishes. Moving on!"
    else
      "Let's talk about the #{room[:label]}."
    end
  end

  def planning_component_for(room)
    if room[:ask_purpose]
      render_component("chat_components/room_purpose", room: room)
    elsif room[:ask_occupants]
      assigned = session.assigned_occupant_keys
      remaining = DemoData.unassigned_family(assigned)
      render_component("chat_components/occupant_selector", room: room, remaining_family: remaining)
    else
      nil
    end
  end

  def planning_component_type_for(room)
    if room[:ask_purpose] then "room_purpose"
    elsif room[:ask_occupants] then "occupant_selector"
    end
  end

  # --- Design helpers ---

  def render_option_selector
    sel_config = session.current_selection_config
    return nil unless sel_config
    prior = session.design_selections.find_by(
      room_key: session.current_room,
      selection_type: sel_config[:type]
    )
    render_component("chat_components/option_selector",
                     session: session, selection: sel_config,
                     room_key: session.current_room, prior_selection: prior)
  end

  def next_component_html
    case session.aasm_state
    when "welcome"        then welcome_component_html
    when "room_planning"  then planning_component_for(DemoData.room(session.current_room) || session.next_unplanned_room)
    when "style_selection" then render_component("chat_components/style_picker", session: session)
    when "designing"      then render_option_selector
    when "summary_review" then render_component("chat_components/summary_card", session: session)
    end
  end

  def next_component_type
    case session.aasm_state
    when "welcome"         then "welcome_prompt"
    when "room_planning"
      room = DemoData.room(session.current_room) || session.next_unplanned_room
      planning_component_type_for(room)
    when "style_selection" then "style_picker"
    when "designing"       then "option_selector"
    when "summary_review"  then "summary_card"
    end
  end

  def confirmation_message_for_selection
    sel_config   = DemoData.selections_for(session.current_room)[session.current_selection_index]
    return "Let's keep going!" unless sel_config
    "Great choice! Now let's look at #{sel_config[:label].downcase}."
  end

  def state_context_description
    state = session.aasm_state
    room  = session.current_room ? DemoData.room(session.current_room)&.dig(:label) : nil
    sel   = session.current_selection_config
    case state
    when "welcome"        then "Welcoming the family and checking if they're ready to start."
    when "room_planning"  then "Assigning purposes and occupants to rooms. Currently on: #{room}."
    when "style_selection" then "Asking the family which design styles resonate with them."
    when "designing"      then "Making finish selections for #{room}, current selection: #{sel&.dig(:label)}."
    when "summary_review" then "Reviewing all selections with the family before finalizing."
    when "complete"       then "All selections are complete. Session is done."
    else "Unknown state."
    end
  end

  # --- Rendering ---

  def render_component(partial, locals = {})
    ApplicationController.renderer.render(
      partial: partial,
      locals: locals
    )
  rescue StandardError => e
    Rails.logger.error("Component render error: #{e.message}")
    nil
  end

  def selection_confirmation_llm_message(room_key:, selection_type:, option_label:, next_selection_label: nil, is_last_in_room: false)
    room   = DemoData.room(room_key)
    styles = session.design_styles_array.filter_map { |k|
      DemoData::DESIGN_STYLES.find { |s| s[:key] == k }&.dig(:label)
    }.join(", ")

    context = "The Morgan family just selected '#{option_label}' for " \
              "#{selection_type.humanize.downcase} in the #{room[:label]}." \
              "#{styles.present? ? " Their design style is #{styles}." : ''}" \
              "#{is_last_in_room ?
                  " This is the final selection — the #{room[:label]} is now fully designed!" :
                  next_selection_label ? " Next up: #{next_selection_label.downcase}." : ''}" \
              " Write exactly 1–2 warm, enthusiastic, personal sentences celebrating this specific choice." \
              "#{is_last_in_room ?
                  " Celebrate completing the room — mention how the choices will come together." :
                  " End with one natural sentence introducing the next selection."}" \
              " Reference the room or their style when it feels natural. No questions. No listing all picks."

    result = @llm.call(
      session: session, lead: lead,
      user_input: "I selected #{option_label}",
      state_context: context,
      history: []
    )
    result["message"]
  rescue StandardError
    is_last_in_room ?
      "The #{room[:label]} is complete — those selections are going to look stunning together!" :
      "Beautiful choice! Now let's look at #{next_selection_label&.downcase || 'the next selection'}."
  end

  def generate_draft_body(question)
    "Hi Megan,\n\nChris and Cindy had a question that came up during their design planning:\n\n" \
    "\"#{question}\"\n\n" \
    "Could you follow up with them when you get a chance? Thank you!\n\n" \
    "— Their Home Companion"
  end
end
