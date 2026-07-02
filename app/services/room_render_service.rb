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

    client = OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_API_KEY"),
      request_timeout: 300
    )
    response = client.images.generate(parameters: {
      model: "gpt-image-1",
      prompt: prompt,
      n: 1,
      size: "1024x1024",
      quality: "low"
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

    room_config = DemoData::ROOMS.find { |r| r[:key] == @room_key }
    room_plan   = @session.room_plans.find_by(room_key: @room_key)

    # Resolve room label — flex rooms use chosen purpose
    purpose_key = nil
    if room_config&.dig(:ask_purpose) && room_plan&.purpose.present?
      purpose_entry = DemoData::FLEX_PURPOSES.find { |p| p[:key] == room_plan.purpose }
      purpose_key   = room_plan.purpose
      room_label    = purpose_entry&.dig(:label) || room_plan.purpose.humanize
    end
    room_label ||= room_config&.dig(:label) || @room_key.humanize

    # Occupant context
    occupant_desc = nil
    if room_plan && room_plan.occupants_array.any?
      members = room_plan.occupant_labels.zip(
        room_plan.occupants_array.map { |k| DemoData.family_member(k) }
      ).filter_map do |name, member|
        next unless member
        "#{name} (#{member[:role]}, #{member[:age_note]})"
      end
      occupant_desc = members.to_sentence if members.any?
    end

    styles = @session.design_styles_array
                     .reject { |k| k == "not_sure" }
                     .filter_map { |k| DemoData::DESIGN_STYLES.find { |s| s[:key] == k }&.dig(:label) }

    # Material finishes
    specs = []
    specs << "#{selections['flooring']} floors"                                                   if selections["flooring"]
    specs << "#{selections['wall_color']} walls"                                                  if selections["wall_color"]
    specs << "#{selections['ceiling']} ceiling"                                                   if selections["ceiling"]
    specs << "#{selections['cabinet_style']} cabinets in #{selections['cabinet_color']}"          if selections["cabinet_style"]
    specs << "#{selections['countertop']} countertops"                                            if selections["countertop"]
    specs << "#{selections['backsplash']} backsplash"                                             if selections["backsplash"]
    specs << "#{selections['hardware']} hardware"                                                 if selections["hardware"]
    specs << "#{selections['vanity']} vanity"                                                     if selections["vanity"]
    specs << "#{selections['floor_tile']} floor tile"                                             if selections["floor_tile"]
    specs << "#{selections['shower_tile']} shower tile"                                           if selections["shower_tile"]
    specs << "#{selections['fixture_finish']} plumbing fixtures"                                  if selections["fixture_finish"]
    specs << "#{selections['fireplace']} fireplace surround"                                      if selections["fireplace"]
    specs << "#{selections['lighting']} lighting fixture"                                         if selections["lighting"]

    style_phrase    = styles.any? ? styles.join(" and ") : "transitional"
    furniture_brief = furniture_for(room_config&.dig(:type), purpose_key, occupant_desc)
    style_brief     = style_decor_for(styles)
    occupant_brief  = occupant_desc ? "The room is designed for #{occupant_desc}." : nil

    <<~PROMPT.squish
      You are a celebrated residential interior designer and architectural visualizer known for
      producing magazine-quality photorealistic 3D renderings for luxury new-construction homes.
      Create a stunning, fully furnished #{room_label} rendered in a #{style_phrase} design aesthetic.

      FINISHES SPECIFIED BY THE HOMEOWNER: #{specs.any? ? specs.join('; ') : 'builder-standard finishes'}.

      FURNITURE AND LAYOUT: #{furniture_brief}

      STYLE AND DECOR: #{style_brief}

      #{occupant_brief}

      RENDERING REQUIREMENTS: Photorealistic 4K quality, professional architectural photography
      perspective, wide-angle view capturing the entire furnished room, abundant warm natural light
      streaming through windows, subtle depth of field, no people, no text overlays.
      The room must look completely move-in ready — every surface styled, every piece of furniture
      perfectly placed, as if photographed for Architectural Digest.
    PROMPT
  end

  def furniture_for(room_type, purpose_key, occupant_desc)
    child_room = occupant_desc&.match?(/8 years old|child|kid/i)

    case room_type
    when :bedroom
      if child_room
        "Twin or full bed with colorful bedding and a playful headboard, matching nightstands with lamps, " \
        "a dresser with a mirror, a small desk and chair for homework, a bookshelf with books and toys, " \
        "a cozy area rug, and wall art suited for a child."
      else
        "A luxurious king-size bed with an upholstered headboard, matching nightstands with table lamps, " \
        "a dresser with a decorative mirror, a cozy accent chair or bench at the foot of the bed, " \
        "an area rug anchoring the space, layered throw pillows, and framed artwork on the walls."
      end
    when :bathroom
      "Plush towels neatly folded on towel bars, a tray of spa-quality toiletries on the vanity counter, " \
      "a large decorative mirror, accent lighting, a potted plant or fresh flowers, " \
      "and a cushioned bath mat on the floor."
    when :kitchen
      "A fully staged kitchen with bar stools at the island, a decorative bowl of fresh fruit, " \
      "a pendant light grouping over the island, open shelving styled with cookbooks and ceramics, " \
      "a small herb garden on the windowsill, and a coordinated canister set on the counter."
    when :living
      "A large sectional or sofa-and-loveseat arrangement facing the fireplace, a substantial coffee table " \
      "with books and a tray centerpiece, two accent chairs, a media console, a floor lamp, " \
      "a generous area rug defining the seating zone, throw pillows and a blanket, " \
      "and gallery wall or large statement artwork above the fireplace."
    when :flex
      flex_furniture_for(purpose_key)
    else
      "Complete furnishings appropriate for the room's function, professionally styled and accessorized."
    end
  end

  def flex_furniture_for(purpose_key)
    case purpose_key
    when "gym"
      "Commercial-quality cardio equipment (treadmill, stationary bike), a functional weight rack with " \
      "dumbbells, floor-to-ceiling mirrors on one wall, rubber flooring tiles, a wall-mounted TV, " \
      "a motivational wall graphic, and a small bench for stretching."
    when "playroom"
      "A low activity table with children's chairs, open toy storage shelving with colorful bins, " \
      "a reading nook with bean bags and a small bookshelf, a soft play mat on the floor, " \
      "a chalkboard or whiteboard wall panel, and bright cheerful wall decor."
    when "office"
      "A large executive desk with a monitor and keyboard, a high-end ergonomic office chair, " \
      "built-in or freestanding bookshelves lined with books, a guest chair, " \
      "a floor lamp, framed artwork or a world map on the wall, and a small potted plant."
    when "guest_room", "bedroom"
      "A queen bed with crisp white bedding and accent pillows, two nightstands with lamps, " \
      "a luggage bench at the foot of the bed, a dresser, a full-length mirror, " \
      "and calming neutral artwork — welcoming and hotel-inspired."
    else
      "Flexible, multi-purpose furnishings tastefully arranged to suit the room, " \
      "fully accessorized and styled for a luxury home."
    end
  end

  def style_decor_for(styles)
    style_keys = styles.map(&:downcase)
    notes = []

    if style_keys.any? { |s| s.include?("contemporary") }
      notes << "clean-lined furniture with minimal ornamentation, a neutral base palette accented with " \
               "one or two bold colors, sculptural lighting fixtures, and curated minimalist accessories"
    end
    if style_keys.any? { |s| s.include?("modern") }
      notes << "bold geometric forms, high-contrast materials (matte black against white or natural wood), " \
               "statement pendant or floor lighting, and sparse but impactful art"
    end
    if style_keys.any? { |s| s.include?("classic") || s.include?("traditional") }
      notes << "rich warm wood tones, ornate furniture silhouettes, layered textiles (velvet, silk, brocade), " \
               "crown molding details, table lamps with fabric shades, and traditional landscape or portrait artwork"
    end
    if style_keys.any? { |s| s.include?("farmhouse") }
      notes << "shiplap accent wall or exposed wood beam details, distressed or reclaimed wood furniture, " \
               "galvanized metal accents, linen and cotton textiles, mason jar or lantern-style lighting, " \
               "and vintage-inspired botanical prints"
    end
    if style_keys.any? { |s| s.include?("transitional") }
      notes << "a balanced blend of classic silhouettes and contemporary finishes, warm neutrals with " \
               "subtle pattern mixing, upholstered pieces in linen or performance fabric, " \
               "brushed nickel or bronze hardware, and timeless artwork"
    end

    notes.any? ? notes.join("; ") : "timeless, well-balanced decor with carefully chosen accessories, " \
                                     "layered textiles, curated art, and lush greenery"
  end
end
