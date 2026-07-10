class MessagesController < ApplicationController
  before_action :require_lead

  def create
    lead = current_lead
    return head :forbidden unless lead.id == params[:lead_id].to_i

    text = params[:content].to_s.strip
    return render json: { error: "empty" }, status: :bad_request if text.blank?

    lead.chat_messages.create!(role: "user", content: text, message_type: "text")

    result = handle_approval_text(text) ||
             DesignFlow.new(session: lead.design_session || lead.create_design_session!, lead: lead).handle_text(text)

    persist_concierge_message(lead, result)
    render json: result.slice(:message, :component_html, :component_type, :state, :rooms_complete, :total_rooms)
  end

  private

  # Handles free-text typed while the buyer is in the approval loop. Returns nil when
  # not in the loop so normal chat handling takes over.
  def handle_approval_text(text)
    case session[:approval_stage]
    when "awaiting_approval"
      if text.match?(/\b(yes|yep|yeah|approve|approved|looks good|love it|perfect|great|sounds good|good|ok|okay)\b/i)
        session.delete(:approval_stage)
        ApprovalFlow.approved_result
      elsif text.match?(/\b(no|nope|change|changes|don'?t|not|fix|different|adjust|redo)\b/i)
        session[:approval_stage] = "collecting_feedback"
        ApprovalFlow.request_feedback_result
      else
        ApprovalFlow.reprompt_result
      end
    when "collecting_feedback"
      ApprovalFlow.feedback_received_result
    end
  end

  def persist_concierge_message(lead, result)
    return if result[:message].blank?
    lead.chat_messages.create!(
      role: "concierge",
      content: result[:message],
      message_type: "text",
      component_type: result[:component_type],
      component_html: result[:component_html]
    )
  end
end
