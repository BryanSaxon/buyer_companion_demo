require "net/http"
require "json"

module GeoipService
  TIMEOUT = 2

  def self.lookup(ip)
    return { city: nil, country: nil } if ip.blank? || local_ip?(ip)

    uri = URI("http://ip-api.com/json/#{ip}?fields=city,country,status")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT
    response = http.get(uri.request_uri)
    data = JSON.parse(response.body)
    return { city: nil, country: nil } unless data["status"] == "success"

    { city: data["city"], country: data["country"] }
  rescue StandardError
    { city: nil, country: nil }
  end

  def self.local_ip?(ip)
    ip.start_with?("127.", "10.", "192.168.", "::1", "localhost")
  end
end
