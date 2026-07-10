# Drives the one-time "approve your selections" loop that greets the buyer when
# they first sign in, before the normal post-design chat. The sub-state lives in
# the cookie session (session[:approval_stage]); this service only builds the
# concierge messages/components for each step.
#
#   awaiting_approval  -> buyer sees the kitchen rendering + approve / request-change buttons
#   collecting_feedback -> buyer types change requests; each is "forwarded to Kassie",
#                          then we ask if there's anything else (with a "that's everything" button)
#   (cleared)          -> approval done; normal chat resumes
module ApprovalFlow
  module_function

  BUYER_NAME = "Michael".freeze

  CONSTRUCTION_MESSAGE =
    "Your design selections are all locked in! Congratulations, you're officially in construction! " \
    "Your home is currently in the Rough-In phase. I'm here any time you have questions about the " \
    "build, your selections, or what comes next. What can I help you with?".freeze

  def intro_message
    "Great job on your design appointment, #{BUYER_NAME}! We have the rendering of your kitchen, " \
    "and we'd like for you to approve the selections you've made."
  end

  def intro_component_html
    render_component("chat_components/approval_card")
  end

  def feedback_prompt_component_html
    render_component("chat_components/approval_feedback_prompt")
  end

  # Buyer approved — celebrate and roll straight into the construction message.
  def approved_result
    { message: "Great! #{CONSTRUCTION_MESSAGE}",
      component_html: nil, component_type: nil, state: "complete" }
  end

  # Buyer wants changes — ask for the details.
  def request_feedback_result
    { message: "Of course — tell me what you'd like changed and I'll pass it straight to Kassie. " \
               "Share as much detail as you'd like.",
      component_html: nil, component_type: nil, state: "complete" }
  end

  # A piece of feedback came in — confirm it's forwarded and ask if there's more.
  def feedback_received_result
    { message: "Thank you, #{BUYER_NAME} — I've sent that over to Kassie and she'll follow up with you " \
               "directly. Is there anything else you'd like to change or add?",
      component_html: feedback_prompt_component_html,
      component_type: "approval_feedback_prompt", state: "complete" }
  end

  # No more feedback — continue to the construction message.
  def done_result
    { message: CONSTRUCTION_MESSAGE, component_html: nil, component_type: nil, state: "complete" }
  end

  # Buyer typed something ambiguous while we were waiting on approve/reject.
  def reprompt_result
    { message: "Just let me know — do the kitchen selections look good to approve, or would you like " \
               "to request a change?",
      component_html: render_component("chat_components/approval_card", show_image: false),
      component_type: "approval_card", state: "complete" }
  end

  def render_component(partial, locals = {})
    ApplicationController.renderer.render(partial: partial, locals: locals)
  rescue StandardError => e
    Rails.logger.error("ApprovalFlow render error: #{e.message}")
    nil
  end
end
