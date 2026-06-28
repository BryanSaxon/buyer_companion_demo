class HomeController < ApplicationController
  before_action :require_lead

  def show
    @lead = current_lead
    @messages = @lead.chat_messages.chronological
  end
end
