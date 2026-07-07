class LeadMailer < ApplicationMailer
  def intake_notification(lead)
    @lead = lead
    @submitted_at = Time.current
    @community = DemoData::COMMUNITY[:name]
    @home = DemoData::HOME

    mail(
      to: Rails.application.credentials.dig(:notifications, :email),
      subject: "New Buyer Inquiry — #{lead.first_name} #{lead.last_name} (#{lead.company})"
    )
  end
end
