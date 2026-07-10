class DemoController < ApplicationController
  def reset
    DemoSeeder.reset_for(current_lead)

    session[:show_welcome]  = true
    session.delete(:approval_stage)
    redirect_to home_path
  end
end
