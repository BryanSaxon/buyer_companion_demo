class IntakeController < ApplicationController
  def show
    if current_lead
      redirect_to home_path
    else
      @builders = Builder.all
      PageView.record(event: "intake_open", request: request)
    end
  end
end
