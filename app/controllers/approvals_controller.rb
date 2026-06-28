class ApprovalsController < ApplicationController
  before_action :require_lead

  def create
    lead = current_lead
    return head :forbidden unless lead.id == params[:lead_id].to_i

    lead.update!(approved_render: true)

    lead.chat_messages.create!(
      role: "companion",
      content: "Approved — I've sent your sign-off on the kitchen to Megan and the production team. Anything you'd still tweak before selections lock on July 28?"
    )

    render json: { success: true }
  end
end
