class RoomRenderService
  def initialize(design_render)
    @render  = design_render
    @session = design_render.design_session
    @room_key = design_render.room_key
  end

  def call
    @render.update!(status: "generating")
    prompt = build_prompt
    @render.update!(prompt: prompt)

    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    response = client.images.generate(parameters: {
      model: "gpt-image-1",
      prompt: prompt,
      n: 1,
      size: "1536x1024",
      quality: "medium"
    })

    b64 = response.dig("data", 0, "b64_json")
    raise "No image data returned from OpenAI" if b64.blank?

    image_data = Base64.decode64(b64)
    @render.image.attach(
      io: StringIO.new(image_data),
      filename: "render-#{@room_key}-#{@render.id}.png",
      content_type: "image/png"
    )
    @render.update!(status: "complete")
  rescue => e
    Rails.logger.error("RoomRenderService failed for render #{@render.id}: #{e.message}\n#{e.respond_to?(:response) ? e.response.inspect : ''}")
    @render.update!(status: "failed")
  end

  private

  def build_prompt
    selections = @session.design_selections
                         .where(room_key: @room_key)
                         .reject(&:pending?)
                         .each_with_object({}) { |s, h| h[s.selection_type] = s.option_label }

    room_label = DemoData::ROOMS.find { |r| r[:key] == @room_key }&.dig(:label) || @room_key.humanize

    styles = @session.design_styles_array
                     .reject { |k| k == "not_sure" }
                     .filter_map { |k| DemoData::DESIGN_STYLES.find { |s| s[:key] == k }&.dig(:label) }

    specs = []
    specs << "#{selections['flooring']} floors"                                                     if selections["flooring"]
    specs << "#{selections['wall_color']} painted walls"                                            if selections["wall_color"]
    specs << "#{selections['ceiling']} ceiling treatment"                                           if selections["ceiling"]
    specs << "#{selections['cabinet_style']} cabinets finished in #{selections['cabinet_color']}"   if selections["cabinet_style"]
    specs << "#{selections['countertop']} countertops"                                              if selections["countertop"]
    specs << "#{selections['backsplash']} backsplash tile"                                          if selections["backsplash"]
    specs << "#{selections['hardware']} hardware and fixtures"                                      if selections["hardware"]
    specs << "#{selections['vanity']} vanity cabinet"                                               if selections["vanity"]
    specs << "#{selections['floor_tile']} floor tile"                                               if selections["floor_tile"]
    specs << "#{selections['shower_tile']} shower tile"                                             if selections["shower_tile"]
    specs << "#{selections['fixture_finish']} plumbing fixtures"                                    if selections["fixture_finish"]
    specs << "#{selections['fireplace']} fireplace surround"                                        if selections["fireplace"]
    specs << "#{selections['lighting']} lighting"                                                   if selections["lighting"]

    style_phrase = styles.any? ? " in a #{styles.join(' and ')} style" : ""

    "Photorealistic interior design rendering of a luxury new-construction #{room_label}#{style_phrase}. " \
    "#{specs.join(', ')}. " \
    "Warm natural light, wide-angle view showing the full room, no people present. " \
    "Premium home builder marketing photography, 4K photorealistic quality."
  end
end
