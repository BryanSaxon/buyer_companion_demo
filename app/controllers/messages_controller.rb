class MessagesController < ApplicationController
  before_action :require_lead

  # Buyer signalling they're done / changed their mind while giving design feedback.
  APPROVAL_DONE_PHRASES = [
    "never mind", "nevermind", "nvm", "changed my mind", "change my mind",
    "on second thought", "no changes", "no change", "no more changes", "no more feedback",
    "nothing else", "that's all", "thats all", "that's it", "thats it",
    "that's everything", "thats everything", "that's fine", "thats fine",
    "it's fine", "its fine", "it's good", "its good", "it's great", "its great",
    "it's perfect", "its perfect", "it's ok", "its ok", "it's okay", "its okay",
    "i'm good", "im good", "i'm fine", "im fine", "i'm done", "im done",
    "i'm all set", "im all set", "all good", "we're good", "were good",
    "leave it", "keep it", "good to go", "no thanks", "no thank you",
    "it is fine", "it is good", "it is great", "it is perfect", "it is ok", "it is okay",
    "that is all", "that is it", "that is everything", "that is fine", "no more"
  ].freeze
  APPROVAL_DONE_RE      = /\b(?:#{APPROVAL_DONE_PHRASES.map { |p| Regexp.escape(p) }.join('|')})\b/i
  APPROVAL_DONE_BARE_RE = /\A(?:no|nope|nah|done|good|fine|ok|okay)[.!]*\z/i

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
      if text.match?(APPROVAL_DONE_RE) || text.strip.match?(APPROVAL_DONE_BARE_RE)
        # Buyer changed their mind or has no more changes — move on.
        session.delete(:approval_stage)
        ApprovalFlow.done_result
      else
        ApprovalFlow.feedback_received_result
      end
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
