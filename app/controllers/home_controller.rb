class HomeController < ApplicationController
  before_action :require_lead

  def show
    @lead = current_lead
    @messages = @lead.chat_messages.chronological
    PageView.record(event: "home_open", request: request, lead: @lead)
  end
end
