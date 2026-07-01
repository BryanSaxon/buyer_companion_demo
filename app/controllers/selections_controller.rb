class SelectionsController < ApplicationController
  before_action :require_lead
  before_action :require_session

  def create
    lead    = current_lead
    session = lead.design_session

    return head :forbidden unless lead.id == params[:lead_id].to_i

    action_data = selection_params
    result = DesignFlow.new(session: session, lead: lead).handle_selection(action_data)

    persist_concierge_message(lead, result)
    render json: result.slice(:message, :component_html, :component_type, :state, :rooms_complete, :total_rooms)
  end

  private

  def selection_params
    p = params.permit(:type, :room_key, :selection_type, :option_key, :option_label,
                      :purpose, :purpose_label, styles: [], occupants: [])
    p.to_h.symbolize_keys
  end

  def require_session
    lead = current_lead
    unless lead&.design_session
      render json: { error: "No active session" }, status: :unprocessable_entity
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
