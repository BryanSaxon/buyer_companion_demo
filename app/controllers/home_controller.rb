class HomeController < ApplicationController
  before_action :require_lead

  def show
    @lead    = current_lead
    @session = @lead.design_session || @lead.create_design_session!(aasm_state: "complete")
    @messages = @lead.chat_messages.chronological

    flow = DesignFlow.new(session: @session, lead: @lead)

    # Show the welcome modal once, right after the buyer signs in or resets the demo.
    # (Flag is set by LeadsController#create and DemoController#reset, then consumed here.)
    @show_welcome_modal = session.delete(:show_welcome).present?

    if @messages.empty?
      if @session.complete?
        # Begin the design-approval loop: greet the buyer with the kitchen rendering to
        # approve before we roll into the "officially in construction" message.
        session[:approval_stage] = "awaiting_approval"
        @lead.chat_messages.create!(
          role: "concierge", content: ApprovalFlow.intro_message, message_type: "text",
          component_type: "approval_card", component_html: ApprovalFlow.intro_component_html
        )
        @initial_component_html = ApprovalFlow.intro_component_html
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
      # Re-show the correct interactive component on refresh, including mid-approval.
      @initial_component_html =
        if !@session.complete?
          flow.next_component_html
        elsif session[:approval_stage] == "awaiting_approval"
          ApprovalFlow.intro_component_html
        elsif session[:approval_stage] == "collecting_feedback"
          ApprovalFlow.feedback_prompt_component_html
        end
    end

    @messages = @lead.chat_messages.chronological
    PageView.record(event: "home_open", request: request, lead: @lead)
  end
end
