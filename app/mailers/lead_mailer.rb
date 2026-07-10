class LeadMailer < ApplicationMailer
  def intake_notification(lead, ip_address: nil)
    @lead = lead
    @submitted_at = Time.current
    @location = geolocate(ip_address)

    mail(
      to: "jarrod@buckerlabs.com",
      subject: "New Buyer Inquiry — #{lead.first_name} #{lead.last_name} (#{lead.company})"
    )
  end

  private

  def geolocate(ip)
    return nil if ip.blank?
    uri = URI("https://ipinfo.io/#{ip}/json")
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    return nil if data["bogon"]
    [ data["city"], data["region"], data["country"] ].compact.reject(&:empty?).join(", ").presence
  rescue StandardError
    nil
  end
end
