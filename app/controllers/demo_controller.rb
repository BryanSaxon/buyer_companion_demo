class DemoController < ApplicationController
  def reset
    lead = current_lead
    if lead.design_session
      lead.design_session.destroy
    end
    lead.chat_messages.delete_all
    redirect_to home_path
  end
end
