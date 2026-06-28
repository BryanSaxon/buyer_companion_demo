class AdminController < ApplicationController
  layout false
  before_action :require_admin_token

  def show
    @leads = Lead.order(created_at: :desc)
    @total_opens = PageView.where(event: "intake_open").count
    @total_home_views = PageView.where(event: "home_open").count

    @lead_stats = @leads.map do |lead|
      views = PageView.where(lead_id: lead.id, event: "home_open").order(:created_at)
      {
        lead: lead,
        first_seen: views.first&.created_at,
        last_seen: views.last&.created_at,
        visit_count: views.count,
        returned: views.count > 1,
        city: views.first&.city,
        country: views.first&.country
      }
    end
  end

  private

  def require_admin_token
    token = ENV.fetch("ADMIN_TOKEN", "bucker2026")
    provided = request.headers["X-Admin-Token"] || params[:token]
    head :unauthorized unless provided == token
  end
end
