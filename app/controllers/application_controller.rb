class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def current_lead
    return @current_lead if defined?(@current_lead)
    @current_lead = Lead.find_by(id: session[:lead_id])
  end

  def require_lead
    redirect_to root_path unless current_lead
  end
end
