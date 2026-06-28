class IntakeController < ApplicationController
  def show
    if current_lead
      redirect_to home_path
    end
  end
end
