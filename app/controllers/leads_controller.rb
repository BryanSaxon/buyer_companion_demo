class LeadsController < ApplicationController
  def create
    @lead = Lead.find_or_initialize_from_params(lead_params)

    if @lead.persisted?
      session[:lead_id] = @lead.id
      LeadMailer.intake_notification(@lead, ip_address: request.remote_ip).deliver_now
      render json: { success: true, lead_id: @lead.id }
      return
    end

    @lead.assign_attributes(lead_params.except(:email))

    if @lead.save
      @lead.create_design_session!(aasm_state: "complete")
      session[:lead_id] = @lead.id
      LeadMailer.intake_notification(@lead, ip_address: request.remote_ip).deliver_now
      render json: { success: true, lead_id: @lead.id }
    else
      render json: { success: false, errors: @lead.errors.as_json }, status: :unprocessable_entity
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :company).tap do |p|
      p[:email] = p[:email].to_s.strip.downcase
    end
  end

end
