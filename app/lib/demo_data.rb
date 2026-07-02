module DemoData
  HOME = {
    community: "Magnolia Grove",
    phase:     "Phase 1",
    lot:       "Lot 24",
    floorplan: "The Bellwood",
    bedrooms:  4,
    bathrooms: 2.5,
    sqft:      "2,340",
    designer:  "Megan Cole"
  }.freeze

  COMMUNITY = {
    name:        "Magnolia Grove",
    tagline:     "Room to grow, minutes from everything.",
    address:     "5400 Magnolia Grove Parkway",
    city:        "Hoover",
    state:       "AL",
    zip:         "35244",
    sales_phone: "(205) 555-0188",
    amenities: [
      "Resort-style pool",
      "Clubhouse",
      "Walking trails",
      "Playground",
      "Dog park",
      "Community green"
    ].freeze,
    hoa: {
      name:             "Magnolia Grove Community Association",
      management:       "Alabama Property Management Group",
      management_phone: "(205) 555-0142",
      management_email: "hello@apmg-hoa.com",
      monthly_dues:     "$95 / month",
      initiation_fee:   "$500 (one-time, at closing)",
      capital_contrib:  "$1,000 (one-time, at closing)",
      covers: "Common-area landscaping, amenity center, trails, community lighting, front entrance, master insurance for common areas."
    }.freeze,
    schools: {
      district:   "Hoover City Schools",
      elementary: "Trace Crossings Elementary (K–5)",
      middle:     "R.F. Bumpus Middle School (6–8)",
      high:       "Hoover High School (9–12)"
    }.freeze,
    floor_plans: [
      { name: "The Ashby",      beds: 3, baths: 2,   sqft: "1,850" },
      { name: "The Bellwood",   beds: 4, baths: 2.5, sqft: "2,340" },
      { name: "The Carrington", beds: 4, baths: 3,   sqft: "2,780" },
      { name: "The Drayton",    beds: 5, baths: 3.5, sqft: "3,210" }
    ].freeze
  }.freeze

  BUILD_STAGES = [
    { key: "foundation", label: "Foundation",            stage: 1, status: :complete,     photos: %w[foundation-lot.jpg foundation-wide.jpg foundation-rebar.jpg foundation-detail.jpg] },
    { key: "framing",    label: "Framing",               stage: 2, status: :complete,     photos: %w[framing-front.jpg framing-side.jpg framing-trusses.jpg framing-interior.jpg] },
    { key: "drywall",    label: "Drywall & Mechanicals", stage: 3, status: :in_progress,  photos: %w[drywall-greatroom.jpg drywall-kitchen.jpg drywall-hallway.jpg drywall-bedroom.jpg] },
    { key: "exterior",   label: "Exterior",              stage: 4, status: :upcoming,     photos: %w[exterior-front.jpg exterior-porch.jpg exterior-garage.jpg exterior-side.jpg] },
    { key: "finishes",   label: "Finishes",              stage: 5, status: :upcoming,     photos: %w[finishes-kitchen.jpg finishes-living.jpg finishes-primary-bath.jpg finishes-bedroom.jpg] }
  ].freeze

  FAMILY = [
    { key: "chris",  name: "Chris",  full: "Chris Morgan",  role: "Dad",      age_note: "adult"       },
    { key: "cindy",  name: "Cindy",  full: "Cindy Morgan",  role: "Mom",      age_note: "adult"       },
    { key: "sarah",  name: "Sarah",  full: "Sarah Morgan",  role: "Daughter", age_note: "8 years old" }
  ].freeze

  ROOMS = [
    { key: "master_bedroom",  label: "Master Bedroom",  type: :bedroom,  ask_purpose: false, ask_occupants: true },
    { key: "master_bathroom", label: "Master Bathroom",  type: :bathroom, ask_purpose: false, ask_occupants: false },
    { key: "bedroom_2",       label: "Bedroom 2",        type: :bedroom,  ask_purpose: false, ask_occupants: true  },
    { key: "bedroom_3",       label: "Bedroom 3",        type: :bedroom,  ask_purpose: false, ask_occupants: true  },
    { key: "bathroom_2",      label: "Bathroom 2",       type: :bathroom, ask_purpose: false, ask_occupants: false },
    { key: "flex_room",       label: "Flex Room",        type: :flex,     ask_purpose: true,  ask_occupants: false },
    { key: "kitchen",         label: "Kitchen",          type: :kitchen,  ask_purpose: false, ask_occupants: false },
    { key: "living_room",     label: "Living Room",      type: :living,   ask_purpose: false, ask_occupants: false }
  ].freeze

  FLEX_PURPOSES = [
    { key: "bedroom",    label: "Bedroom"      },
    { key: "playroom",   label: "Playroom"     },
    { key: "gym",        label: "Home Gym"     },
    { key: "office",     label: "Home Office"  },
    { key: "guest_room", label: "Guest Room"   },
    { key: "other",      label: "Other…"       },
    { key: "not_sure",   label: "Not sure yet" }
  ].freeze

  DESIGN_STYLES = [
    {
      key: "contemporary", label: "Contemporary", desc: "Clean lines, neutral palette, open space",
      about: "Effortlessly refined and right now. Contemporary design embraces open, airy spaces with a " \
             "neutral base palette — whites, warm greiges, and soft grays — punctuated by carefully chosen " \
             "accent tones. Furniture is sleek and uncluttered, materials mix thoughtfully (linen, marble, " \
             "brushed metal), and every detail feels intentional. The result is a home that feels calm, " \
             "sophisticated, and genuinely livable.",
      image: "design/styles/style_contemporary.jpg"
    },
    {
      key: "modern", label: "Modern", desc: "Bold minimalism, high contrast, statement pieces",
      about: "Architecture as art. Modern style strips away the ornamental and lets form follow function — " \
             "but with drama. Expect high-contrast pairings (matte black against white, concrete beside warm " \
             "wood), geometric furniture silhouettes, and lighting that makes a statement. Every piece earns " \
             "its place. The spaces feel bold, curated, and unapologetically striking.",
      image: "design/styles/style_modern.jpg"
    },
    {
      key: "traditional", label: "Classic / Traditional", desc: "Warm woods, ornate details, timeless comfort",
      about: "Timeless elegance that never goes out of fashion. Traditional design draws on centuries of " \
             "European craftsmanship — rich hardwoods, detailed millwork, crown molding, and layered textiles " \
             "in velvets, silks, and damasks. Furniture is substantial and graceful, rooms feel warm and " \
             "welcoming, and the overall effect is one of enduring quality and understated luxury.",
      image: "design/styles/style_traditional.jpg"
    },
    {
      key: "farmhouse", label: "Farmhouse", desc: "Shiplap, warm whites, natural textures",
      about: "Relaxed, rooted, and full of soul. Farmhouse style brings the warmth of the countryside " \
             "indoors — shiplap walls, reclaimed wood beams, galvanized metal accents, and a palette of " \
             "warm whites and earthy naturals. Linen, cotton, and chunky knit textiles add texture; vintage " \
             "finds and handcrafted pieces add character. It's casual enough for real life, beautiful enough " \
             "for any magazine.",
      image: "design/styles/style_farmhouse.jpg"
    },
    {
      key: "transitional", label: "Transitional", desc: "Classic meets contemporary, balanced warmth",
      about: "The best of both worlds, perfectly balanced. Transitional design pairs classic furniture " \
             "silhouettes with contemporary finishes — think an upholstered sofa in a clean-lined profile, " \
             "or traditional trim work alongside streamlined cabinetry. Warm neutrals, subtle pattern mixing, " \
             "and materials like brushed nickel and natural stone tie it together. Approachable, " \
             "versatile, and always in style.",
      image: "design/styles/style_transitional.jpg"
    },
    {
      key: "not_sure", label: "Not sure yet", desc: "We'll explore together at your design meeting",
      about: nil, image: nil
    }
  ].freeze

  FLOORING_OPTIONS = [
    { key: "hardwood_oak", label: "Natural Oak Hardwood", swatch: "#C8A97E", image: "design/flooring/flooring-coastal-oak.jpg" },
    { key: "lvp_ash",      label: "Ash Grey LVP",         swatch: "#9DA8A0", image: "design/flooring/flooring-slate-grey-lvp.jpg" },
    { key: "carpet_oat",   label: "Warm Oat Carpet",      swatch: "#D4C8A8", image: "design/flooring/flooring-warm-oat-carpet.jpg" }
  ].freeze

  NEUTRAL_WALL_OPTIONS = [
    { key: "white_classic", label: "Classic White", swatch: "#F5F4EF" },
    { key: "greige_warm",   label: "Warm Greige",   swatch: "#C4B8A4" },
    { key: "navy_deep",     label: "Deep Navy",     swatch: "#1C2C4A" },
    { key: "sage_soft",     label: "Soft Sage",     swatch: "#8FA58E" }
  ].freeze

  FIXTURE_OPTIONS = [
    { key: "matte_black",     label: "Matte Black",       swatch: "#2A2A2A", image: "design/hardware/hardware-matte-black.jpg" },
    { key: "brushed_nickel",  label: "Brushed Nickel",    swatch: "#9EA4A8", image: "design/hardware/hardware-brushed-nickel.jpg" },
    { key: "polished_chrome", label: "Polished Chrome",   swatch: "#C8CDD4", image: "design/hardware/hardware-polished-chrome.jpg" },
    { key: "warm_gold",       label: "Champagne Bronze",  swatch: "#C8A84B", image: "design/hardware/hardware-champagne-bronze.jpg" }
  ].freeze

  SELECTIONS = {
    "master_bedroom" => [
      { type: "flooring",   label: "Flooring",          multi: false, options: FLOORING_OPTIONS },
      { type: "wall_color", label: "Wall Color",         multi: false, options: NEUTRAL_WALL_OPTIONS },
      { type: "ceiling",    label: "Ceiling Treatment",  multi: false, options: [
        { key: "standard", label: "Standard Flat", swatch: "#F5F4EF", image: "design/ceiling/ceiling-standard.jpg" },
        { key: "tray",     label: "Tray Ceiling",  swatch: "#E8E0D0", image: "design/ceiling/ceiling-tray.jpg" },
        { key: "coffered", label: "Coffered",      swatch: "#D4C8B0", image: "design/ceiling/ceiling-coffered.jpg" }
      ] }
    ],
    "master_bathroom" => [
      { type: "floor_tile",     label: "Floor Tile",    multi: false, options: [
        { key: "carrara_marble", label: "Carrara Marble Look", swatch: "#E8E4DC", image: "design/flooring/flooring-carrara-tile.jpg" },
        { key: "large_grey",     label: "Large Format Grey",   swatch: "#9EA4A8", image: "design/tile/tile-large-grey.jpg" },
        { key: "hex_white",      label: "White Hex Mosaic",    swatch: "#F0EFEB", image: "design/tile/tile-hex-white.jpg" }
      ] },
      { type: "shower_tile",    label: "Shower Tile",   multi: false, options: [
        { key: "subway_white",   label: "White Subway",         swatch: "#F2F0EB", image: "design/tile/tile-subway-white.jpg" },
        { key: "vertical_stack", label: "Vertical Stack",       swatch: "#E0DDD4", image: "design/tile/tile-vertical-stack.jpg" },
        { key: "moroccan",       label: "Moroccan Pattern",     swatch: "#C8C0B0", image: "design/tile/tile-moroccan.jpg" }
      ] },
      { type: "vanity",         label: "Vanity Style",  multi: false, options: [
        { key: "shaker_white", label: "Shaker White",       swatch: "#F0EDE8", image: "design/vanity/vanity-shaker-white.jpg" },
        { key: "modern_grey",  label: "Modern Grey",        swatch: "#888E94", image: "design/vanity/vanity-modern-grey.jpg" },
        { key: "wood_tone",    label: "Natural Wood Tone",  swatch: "#A07850", image: "design/vanity/vanity-wood-tone.jpg" }
      ] },
      { type: "fixture_finish", label: "Fixture Finish", multi: false, options: FIXTURE_OPTIONS }
    ],
    "bedroom_2" => [
      { type: "flooring",   label: "Flooring",   multi: false, options: FLOORING_OPTIONS },
      { type: "wall_color", label: "Wall Color",  multi: false, options: [
        { key: "white_classic", label: "Classic White",  swatch: "#F5F4EF" },
        { key: "blush",         label: "Soft Blush",     swatch: "#E8C8B8" },
        { key: "lavender",      label: "Lavender Mist",  swatch: "#C4BAD8" },
        { key: "sky_blue",      label: "Sky Blue",       swatch: "#A8C4D8" }
      ] }
    ],
    "bedroom_3" => [
      { type: "flooring",   label: "Flooring",   multi: false, options: FLOORING_OPTIONS },
      { type: "wall_color", label: "Wall Color",  multi: false, options: [
        { key: "white_classic", label: "Classic White", swatch: "#F5F4EF" },
        { key: "greige_warm",   label: "Warm Greige",   swatch: "#C4B8A4" },
        { key: "navy_deep",     label: "Deep Navy",     swatch: "#1C2C4A" },
        { key: "forest_green",  label: "Forest Green",  swatch: "#3A5A44" }
      ] }
    ],
    "bathroom_2" => [
      { type: "floor_tile",     label: "Floor Tile",    multi: false, options: [
        { key: "carrara_marble", label: "Carrara Marble Look", swatch: "#E8E4DC", image: "design/flooring/flooring-carrara-tile.jpg" },
        { key: "large_grey",     label: "Large Format Grey",   swatch: "#9EA4A8", image: "design/tile/tile-large-grey.jpg" },
        { key: "hex_white",      label: "White Hex Mosaic",    swatch: "#F0EFEB", image: "design/tile/tile-hex-white.jpg" }
      ] },
      { type: "vanity",         label: "Vanity Style",  multi: false, options: [
        { key: "shaker_white", label: "Shaker White",      swatch: "#F0EDE8", image: "design/vanity/vanity-shaker-white.jpg" },
        { key: "modern_grey",  label: "Modern Grey",       swatch: "#888E94", image: "design/vanity/vanity-modern-grey.jpg" },
        { key: "wood_tone",    label: "Natural Wood Tone", swatch: "#A07850", image: "design/vanity/vanity-wood-tone.jpg" }
      ] },
      { type: "fixture_finish", label: "Fixture Finish", multi: false, options: FIXTURE_OPTIONS }
    ],
    "flex_room" => [
      { type: "flooring",   label: "Flooring",   multi: false, options: FLOORING_OPTIONS },
      { type: "wall_color", label: "Wall Color",  multi: false, options: NEUTRAL_WALL_OPTIONS }
    ],
    "kitchen" => [
      { type: "cabinet_style", label: "Cabinet Style", multi: false, options: [
        { key: "shaker",       label: "Shaker",       swatch: "#E8E4DC", image: "design/cabinets/cabinet-shaker-white.jpg" },
        { key: "flat_panel",   label: "Flat Panel",   swatch: "#D4D0C8", image: "design/cabinets/cabinet-flat-panel.jpg" },
        { key: "raised_panel", label: "Raised Panel", swatch: "#C8BEA8", image: "design/cabinets/cabinet-raised-panel.jpg" }
      ] },
      { type: "cabinet_color", label: "Cabinet Color", multi: false, options: [
        { key: "alpine_white", label: "Alpine White",   swatch: "#F2EFE8", image: "design/cabinets/cabinet-shaker-white.jpg" },
        { key: "greige",       label: "Soft Greige",    swatch: "#C4B8A4" },
        { key: "hale_navy",    label: "Hale Navy",      swatch: "#2A3A50", image: "design/cabinets/cabinet-harbor-navy.jpg" },
        { key: "charcoal",     label: "Natural Walnut", swatch: "#3A3A3A", image: "design/cabinets/cabinet-natural-walnut.jpg" }
      ] },
      { type: "countertop", label: "Countertop", multi: false, options: [
        { key: "calacatta_quartz", label: "Calacatta Gold Quartz", swatch: "#E8E0CC", image: "design/countertop/countertop-calacatta-quartz.jpg" },
        { key: "carrara_quartz",   label: "Carrara Quartz",        swatch: "#E4E0D8", image: "design/countertop/countertop-carrara-quartz.jpg" },
        { key: "quartz_black",     label: "Midnight Quartz",       swatch: "#2A2A2C", image: "design/countertop/countertop-midnight-quartz.jpg" },
        { key: "butcher_block",    label: "Butcher Block",         swatch: "#B88850", image: "design/countertop/countertop-butcher-block.jpg" }
      ] },
      { type: "backsplash", label: "Backsplash", multi: false, options: [
        { key: "subway_gloss", label: "White Subway Gloss", swatch: "#F0EFEB", image: "design/backsplash/backsplash-subway.jpg" },
        { key: "zellige",      label: "Zellige White",      swatch: "#EAE8E0", image: "design/backsplash/backsplash-zellige.jpg" },
        { key: "matte_grey",   label: "Matte Grey",         swatch: "#9EA4A8", image: "design/backsplash/backsplash-matte-grey.jpg" },
        { key: "hex_mosaic",   label: "White Hex Mosaic",   swatch: "#ECEAE4", image: "design/backsplash/backsplash-hex-mosaic.jpg" }
      ] },
      { type: "hardware", label: "Hardware", multi: false, options: [
        { key: "matte_black",    label: "Matte Black",      swatch: "#2A2A2A", image: "design/hardware/hardware-matte-black.jpg" },
        { key: "brushed_nickel", label: "Brushed Nickel",   swatch: "#9EA4A8", image: "design/hardware/hardware-brushed-nickel.jpg" },
        { key: "warm_gold",      label: "Champagne Bronze", swatch: "#C8A84B", image: "design/hardware/hardware-champagne-bronze.jpg" },
        { key: "chrome",         label: "Polished Chrome",  swatch: "#C8CDD4", image: "design/hardware/hardware-polished-chrome.jpg" }
      ] }
    ],
    "living_room" => [
      { type: "flooring",   label: "Flooring",           multi: false, options: FLOORING_OPTIONS },
      { type: "wall_color", label: "Wall Color",          multi: false, options: [
        { key: "white_classic", label: "Classic White", swatch: "#F5F4EF" },
        { key: "warm_white",    label: "Warm White",    swatch: "#F0EAE0" },
        { key: "greige_warm",   label: "Warm Greige",   swatch: "#C4B8A4" },
        { key: "slate_blue",    label: "Slate Blue",    swatch: "#6A7F9A" }
      ] },
      { type: "fireplace", label: "Fireplace Surround", multi: false, options: [
        { key: "standard",         label: "Standard Surround",     swatch: "#E8E0D0", image: "design/fireplace/fireplace-standard.jpg" },
        { key: "floor_to_ceiling", label: "Floor-to-Ceiling Tile", swatch: "#9EA4A8", image: "design/fireplace/fireplace-floor-to-ceiling.jpg" },
        { key: "shiplap",          label: "Shiplap Surround",      swatch: "#F0EDEA", image: "design/fireplace/fireplace-shiplap.jpg" }
      ] },
      { type: "lighting", label: "Lighting Package", multi: false, options: [
        { key: "brass_pendant", label: "Brass Pendant",  swatch: "#C8A84B", image: "design/fixtures/light-brass-pendant.jpg" },
        { key: "ceiling_fan",   label: "Ceiling Fan",    swatch: "#9EA4A8", image: "design/fixtures/light-ceiling-fan.jpg" },
        { key: "recessed_led",  label: "Recessed LED",   swatch: "#F0EFEB", image: "design/fixtures/light-recessed-led.jpg" }
      ] }
    ]
  }.freeze

  def self.room(key)
    ROOMS.find { |r| r[:key] == key.to_s }
  end

  def self.selections_for(room_key)
    SELECTIONS[room_key.to_s] || []
  end

  def self.family_member(key)
    FAMILY.find { |f| f[:key] == key.to_s }
  end

  def self.unassigned_family(assigned_keys)
    FAMILY.reject { |f| assigned_keys.include?(f[:key]) }
  end

  def self.next_design_meeting_date
    today = Date.today
    days = (3 - today.wday) % 7
    days = 7 if days.zero?
    (today + days).strftime("%A, %B %-d")
  end
end
