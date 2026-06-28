class IntakeController < ApplicationController
  def show
    if current_lead
      redirect_to home_path
    else
      PageView.record(event: "intake_open", request: request)
    end
  end
end
