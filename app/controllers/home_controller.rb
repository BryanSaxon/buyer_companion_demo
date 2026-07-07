class HomeController < ApplicationController
  before_action :require_lead

  def show
    @lead    = current_lead
    @session = @lead.design_session || @lead.create_design_session!(aasm_state: "complete")
    @messages = @lead.chat_messages.chronological

    flow = DesignFlow.new(session: @session, lead: @lead)

    if @messages.empty?
      if @session.complete?
        msg = post_design_welcome(@lead)
        @lead.chat_messages.create!(
          role: "concierge", content: msg, message_type: "text",
          component_type: nil, component_html: nil
        )
        @initial_component_html = nil
      else
        msg  = flow.welcome_message
        html = flow.welcome_component_html
        @lead.chat_messages.create!(
          role: "concierge", content: msg, message_type: "text",
          component_type: "welcome_prompt", component_html: html
        )
        @initial_component_html = html
      end
    else
      @initial_component_html = @session.complete? ? nil : flow.next_component_html
    end

    @messages = @lead.chat_messages.chronological
    PageView.record(event: "home_open", request: request, lead: @lead)
  end

  private

  def post_design_welcome(lead)
    family = DemoData::FAMILY.select { |m| m[:age_note] == "adult" }.map { |m| m[:name] }
    names  = family.any? ? family.first(2).join(" and ") : "there"
    status = DemoData::BUILD_STATUS
    "Hi #{names}! Your design selections are all locked in — congratulations, you're officially in construction! " \
    "Your home is currently in the #{status[:current_phase_short]} phase. " \
    "I'm here any time you have questions about the build, your selections, or what comes next. What's on your mind?"
  end
end
