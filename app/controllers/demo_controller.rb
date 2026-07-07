class DemoController < ApplicationController
  def reset
    lead = current_lead
    lead.chat_messages.delete_all
    lead.design_session&.destroy

    DemoSeeder.seed_harrison_session(lead)

    redirect_to home_path
  end
end
