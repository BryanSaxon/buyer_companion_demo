class MessagesController < ApplicationController
  before_action :require_lead

  def create
    lead = current_lead
    return head :forbidden unless lead.id == params[:lead_id].to_i

    text = params[:content].to_s.strip
    return render json: { error: "empty" }, status: :bad_request if text.blank?

    lead.chat_messages.create!(role: "user", content: text, message_type: "text")

    session = lead.design_session || lead.create_design_session!
    result  = DesignFlow.new(session: session, lead: lead).handle_text(text)

    lead.chat_messages.create!(
      role: "concierge",
      content: result[:message],
      message_type: "text",
      component_type: result[:component_type],
      component_html: result[:component_html]
    )

    render json: result.slice(:message, :component_html, :component_type, :state, :rooms_complete, :total_rooms)
  end
end
