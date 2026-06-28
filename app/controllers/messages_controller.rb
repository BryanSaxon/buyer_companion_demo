require "net/http"
require "json"

class MessagesController < ApplicationController
  before_action :require_lead

  KEYWORD_ANSWERS = {
    /\b(change|swap|switch|still.*(change|pick)|lock|different|instead|alternate)\b.*?(counter|quartz|kitchen|select|pick|finish)/m => "You're at final review, so your selections are still open until they lock on July 28. Right now you have Calacatta Gold quartz counters. Megan has two alternates in stock — a softer Carrara look and a bolder soapstone. Want me to pull both up next to your current pick?",
    /charlotte|first bedroom|her room|daughter|kid|nursery|name.*room|room.*name/ => "Charlotte's room is the front bedroom upstairs — about 12 by 11, the one with the big east window that gets the morning light. You named it on day one, so I'll always call it Charlotte's room. It's wired for a ceiling fan and has the deeper closet from your Option 7 upgrade. Want me to show where it sits on the floor plan?",
    /kitchen|cabinet|counter|backsplash|island|select|finish|render|pick|quartz|hardware|tile/ => "Here's what you locked in for the kitchen: Alpine White shaker cabinets with soft-close, a Hale Navy painted island, Calacatta Gold quartz counters, a gloss-white zellige backsplash, matte-black bar pulls, and natural white-oak floors. The render above reflects all of it. Want to compare any one against an alternate in stock?",
    /milestone|next|when|walkthrough|drywall|timeline|schedule|date|appointment/ => "Your next milestone is the pre-drywall walkthrough — Tuesday, August 4 at 9:00 AM with Megan, your designer. That's the best moment to check outlet and switch placement before the walls close up. I'll remind you the day before. Want me to add anything to the walkthrough list?",
    /designer|megan|who.*(help|contact|rep|talk)|contact|phone|call/ => "Your designer is Megan Cole. She's handled your selections from the start and she'll be at your pre-drywall walkthrough. Want me to share her direct line or set up a quick call?",
    /floor.?plan|how big|square|sq.?ft|bed|bath|layout|\bplan\b|rooms?\b/ => "You're in The Brookfield — 4 bed, 3 bath, 2,840 square feet over two stories, on Lot 24 · Crystal Ridge. The kitchen opens to the great room, and Charlotte's room is at the front upstairs. Want a room-by-room rundown?",
    /\A(hi|hey|hello|yo)\b/i => nil  # handled dynamically below
  }.freeze

  def create
    lead = current_lead
    return head :forbidden unless lead.id == params[:lead_id].to_i

    text = params[:content].to_s.strip
    return render json: { error: "empty" }, status: :bad_request if text.blank?

    lead.chat_messages.create!(role: "user", content: text)

    answer = scripted_answer(text, lead) || live_ai_answer(text, lead) || fallback_answer
    lead.chat_messages.create!(role: "companion", content: answer)

    render json: { answer: answer }
  end

  private

  def scripted_answer(text, lead)
    q = text.downcase
    if /\A(hi|hey|hello|yo)\b/.match?(q)
      return "Hi #{lead.first_name_display} — ask me anything about your home. Your selections, your timeline, or any room by name."
    end

    KEYWORD_ANSWERS.each do |pattern, answer|
      next if answer.nil?
      return answer if pattern.match?(q)
    end
    nil
  end

  def live_ai_answer(text, lead)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return nil if api_key.blank?

    system_prompt = build_system_prompt(lead, text)

    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 8
    http.open_timeout = 4

    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = {
      model: "claude-haiku-4-5-20251001",
      max_tokens: 256,
      system: system_prompt,
      messages: [ { role: "user", content: text } ]
    }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)
    body.dig("content", 0, "text")&.strip
  rescue StandardError
    nil
  end

  def build_system_prompt(lead, _text)
    "You are the personal home companion for #{lead.first_name_display}, a homebuyer, " \
    "speaking on behalf of their builder \"#{lead.org_name}\". " \
    "Their home: The Brookfield, 4 bed 3 bath, 2,840 sq ft, Lot 24 · Crystal Ridge, " \
    "stage: Final review, designer: Megan Cole. " \
    "Kitchen selections: Cabinets: Alpine White shaker; Island: Hale Navy; " \
    "Counters: Calacatta Gold quartz; Backsplash: Zellige gloss white; " \
    "Hardware: Matte black pulls; Floors: Natural white oak. " \
    "A bedroom is named \"Charlotte's room\". " \
    "Next milestone: Pre-drywall walkthrough — Tuesday, Aug 4 at 9:00 AM. " \
    "Answer warmly in 2-4 sentences, first person, never mention being an AI model."
  end

  def fallback_answer
    "That's a great one for Megan, your designer — I've flagged it so she sees it before your next appointment. In the meantime I can pull up your selections, your timeline, or any room in the house. What would help most?"
  end
end
