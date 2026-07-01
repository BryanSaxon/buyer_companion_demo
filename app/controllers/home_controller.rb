class HomeController < ApplicationController
  before_action :require_lead

  def show
    @lead    = current_lead
    @session = @lead.design_session || @lead.create_design_session!
    @messages = @lead.chat_messages.chronological

    # Fire welcome message for brand-new sessions
    if @messages.empty?
      flow = DesignFlow.new(session: @session, lead: @lead)
      msg  = flow.welcome_message
      html = flow.welcome_component_html
      @lead.chat_messages.create!(role: "concierge", content: msg, message_type: "text", component_type: "welcome_prompt")
      @initial_component_html = html
    end

    @messages = @lead.chat_messages.chronological
    PageView.record(event: "home_open", request: request, lead: @lead)
  end
end
