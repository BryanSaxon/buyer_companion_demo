class GenerateRoomRenderJob < ApplicationJob
  queue_as :default

  def perform(design_render_id)
    render_record = DesignRender.find_by(id: design_render_id)
    return unless render_record&.status.in?(%w[pending failed])

    RoomRenderService.new(render_record).call
  end
end
