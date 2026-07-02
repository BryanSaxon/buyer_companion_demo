class RendersController < ApplicationController
  def show
    lead = Lead.find(params[:lead_id])
    dr   = lead.design_session&.design_renders&.find_by(room_key: params[:room_key])

    if dr&.status == "complete" && dr.image.attached?
      render json: { status: "complete", image_url: url_for(dr.image) }
    else
      render json: { status: dr&.status || "pending" }
    end
  end
end
