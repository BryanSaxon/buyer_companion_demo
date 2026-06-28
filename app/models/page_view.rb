class PageView < ApplicationRecord
  belongs_to :lead, optional: true

  EVENTS = %w[intake_open home_open].freeze

  def self.record(event:, request:, lead: nil)
    create!(
      event: event,
      lead: lead,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s.truncate(300)
    )
  rescue StandardError
    # never let tracking blow up the request
  end
end
