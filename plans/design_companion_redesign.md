# Design Companion Redesign

**Status:** Ready to implement  
**Last updated:** 2026-06-29  

---

## What We're Building

Transform the current "final review" demo into a guided, interactive design planning experience. The AI companion walks the Morgan family through every room in their new home — assigning purpose, selecting style, and making design choices one by one — before their design meeting with their builder.

The chat IS the app. The left panel becomes a Design Brief dashboard (progress tracker, property details, family).

---

## Decisions Resolved

| Decision | Resolution |
|---|---|
| LangChain | Skip — direct `anthropic` gem + AASM state machine |
| ActionMCP | Skip — not applicable to this pattern |
| `aasm` gem | Add to Gemfile |
| `anthropic` gem | Add to Gemfile (replace raw Net::HTTP) |
| Style picker images | Unsplash via curl, saved locally to `app/assets/images/design/styles/` |
| Option selector visuals | CSS color swatches for MVP (no product photography needed) |
| Draft email | Store in DB (`draft_emails` table), show in chat as copy-only card, never send |
| Existing approve flow | Remove entirely (ApprovalsController, approval route, approved_render column) |
| Mobile tab label | Keep "My home" — the Design Brief is contextually "your home info" |
| Summary view | In-chat summary card (not a separate screen) |
| Welcome back | Auto-send warm "welcome back" message resuming from current state |
| Design meeting date | Calculate as next Wednesday from `Date.today` at session completion |
| Family last name | Morgan |
| Sarah's age | 8 years old |
| Designer name | Megan Cole |

---

## Fixed Demo Data

**Family:** Chris Morgan (Dad), Cindy Morgan (Mom), Sarah Morgan (Daughter, 8)  
**Home:** Crystal Ridge · Phase 2 · Lot 24 · The Brookfield  
**Rooms:** 3 bed · 2 bath · 1 flex room · kitchen · living room  
**Sq ft:** 1,842  
**Designer:** Megan Cole  

This data is the same for every builder who uses the demo. Only the builder's company name (from intake) varies, displayed as the brand in the UI.

---

## Architecture

### The Core Pattern

```
User input (text or selection tap)
  → MessagesController or SelectionsController
    → DesignSession (AASM) determines current state
      → CompanionLlm generates warm language for this moment
        → Server packages: { message, component_html, state, rooms_complete }
          → Stimulus appends text bubble + component card to chat
```

**LLM role:** Generate warm, constrained language only. Never drives flow or component selection.  
**State machine role:** Controls what state we're in, what component renders next, when to advance.  
**Components:** Server-rendered Rails partials, returned as HTML in JSON, inserted by Stimulus.

### Structured LLM Response

Every Claude call returns JSON with exactly:
```json
{
  "message": "Warm companion text, 1–3 sentences",
  "can_advance": true,
  "is_off_topic": false,
  "draft_email_reason": null
}
```

### Two Controller Paths

- **MessagesController** — free text input → LLM → text bubble + optional component  
- **SelectionsController** — structured taps (component interactions) → state advance → LLM confirmation text + next component

Both return the same JSON shape. Stimulus handles both identically.

---

## Room Order

Planning phase and design phase follow this order:

1. Master Bedroom (Chris & Cindy — never ask who sleeps here)
2. Master Bathroom
3. Bedroom 2 (ask who sleeps here)
4. Bedroom 3 (ask who sleeps here — if all family assigned, offer guest/skip)
5. Bathroom 2
6. Flex Room (ask purpose)
7. Kitchen
8. Living Room

---

## Database Schema

### New Tables

**`design_sessions`**
```
id, lead_id (unique), aasm_state, current_room, current_selection_index,
planning_complete, style_selected, summary_approved, timestamps
```

**`room_plans`**
```
id, design_session_id, room_key, purpose, purpose_label, occupants (JSON text),
skipped, complete, timestamps
UNIQUE (design_session_id, room_key)
```

**`design_selections`**
```
id, design_session_id, room_key, selection_type, option_key, option_label,
pending, timestamps
UNIQUE (design_session_id, room_key, selection_type)
```

**`draft_emails`**
```
id, design_session_id, original_question, subject, body, timestamps
```

### Modify Existing

- **`chat_messages`**: add `message_type` (string, default: "text"), `component_type` (string, nullable)
- **`leads`**: remove `approved_render` column (migration with `remove_column`)

### AASM States on DesignSession

```
welcome → room_planning → style_selection → designing → summary_review → complete
```

`room_planning` and `designing` use `current_room` + `current_selection_index` as sub-cursors within those states.

---

## Catalog Data

Stored in `app/lib/demo_data.rb` as Ruby constants (not DB rows — catalog doesn't change).

### Rooms Config (keys, labels, types, what to ask)

```ruby
ROOMS = [
  { key: "master_bedroom",  label: "Master Bedroom",  type: :bedroom,  ask_purpose: false, ask_occupants: false, default_occupants: ["chris","cindy"] },
  { key: "master_bathroom", label: "Master Bathroom",  type: :bathroom, ask_purpose: false, ask_occupants: false },
  { key: "bedroom_2",       label: "Bedroom 2",        type: :bedroom,  ask_purpose: false, ask_occupants: true  },
  { key: "bedroom_3",       label: "Bedroom 3",        type: :bedroom,  ask_purpose: false, ask_occupants: true  },
  { key: "bathroom_2",      label: "Bathroom 2",       type: :bathroom, ask_purpose: false, ask_occupants: false },
  { key: "flex_room",       label: "Flex Room",        type: :flex,     ask_purpose: true,  ask_occupants: false },
  { key: "kitchen",         label: "Kitchen",          type: :kitchen,  ask_purpose: false, ask_occupants: false },
  { key: "living_room",     label: "Living Room",      type: :living,   ask_purpose: false, ask_occupants: false },
]

FLEX_PURPOSES = [
  { key: "playroom",    label: "Playroom"    },
  { key: "gym",         label: "Home Gym"    },
  { key: "office",      label: "Home Office" },
  { key: "guest_room",  label: "Guest Room"  },
  { key: "other",       label: "Other..."    },
  { key: "not_sure",    label: "Not sure yet"},
]

FAMILY = [
  { key: "chris",  name: "Chris",  full: "Chris Morgan",  role: "Dad",      age_note: "adult"        },
  { key: "cindy",  name: "Cindy",  full: "Cindy Morgan",  role: "Mom",      age_note: "adult"        },
  { key: "sarah",  name: "Sarah",  full: "Sarah Morgan",  role: "Daughter", age_note: "8 years old"  },
]

HOME = {
  community: "Crystal Ridge", phase: "Phase 2", lot: "Lot 24",
  floorplan: "The Brookfield", bedrooms: 3, bathrooms: 2, sqft: "1,842",
  designer: "Megan Cole",
}
```

### Design Styles

```ruby
DESIGN_STYLES = [
  { key: "contemporary",  label: "Contemporary",        desc: "Clean lines, neutral palette, open space",       image: "style_contemporary.jpg"  },
  { key: "modern",        label: "Modern",              desc: "Bold minimalism, high contrast, statement pieces", image: "style_modern.jpg"        },
  { key: "traditional",   label: "Classic / Traditional", desc: "Warm woods, ornate details, timeless comfort",  image: "style_traditional.jpg"   },
  { key: "farmhouse",     label: "Farmhouse",           desc: "Shiplap, warm whites, natural textures",         image: "style_farmhouse.jpg"     },
  { key: "transitional",  label: "Transitional",        desc: "Classic meets contemporary, balanced warmth",     image: "style_transitional.jpg"  },
  { key: "not_sure",      label: "Not sure yet",        desc: "We'll explore at the design meeting",            image: nil                       },
]
```

Images live at `app/assets/images/design/styles/[filename]`. Downloaded from Unsplash via curl at setup time.

### Selection Catalog

```ruby
SELECTIONS = {
  "master_bedroom" => [
    { type: "flooring",    label: "Flooring",         multi: false, options: [
      { key: "hardwood_oak",    label: "Natural Oak Hardwood",  swatch: "#C8A97E" },
      { key: "lvp_ash",         label: "Ash Grey LVP",          swatch: "#9DA8A0" },
      { key: "carpet_oat",      label: "Warm Oat Carpet",       swatch: "#D4C8A8" },
    ]},
    { type: "wall_color",  label: "Wall Color",       multi: false, options: [
      { key: "white_classic",   label: "Classic White",         swatch: "#F5F4EF" },
      { key: "greige_warm",     label: "Warm Greige",           swatch: "#C4B8A4" },
      { key: "navy_deep",       label: "Deep Navy",             swatch: "#1C2C4A" },
      { key: "sage_soft",       label: "Soft Sage",             swatch: "#8FA58E" },
    ]},
    { type: "ceiling",     label: "Ceiling Treatment", multi: false, options: [
      { key: "standard",        label: "Standard Flat",         swatch: "#F5F4EF" },
      { key: "tray",            label: "Tray Ceiling",          swatch: "#E8E0D0" },
      { key: "coffered",        label: "Coffered",              swatch: "#D4C8B0" },
    ]},
  ],
  "master_bathroom" => [
    { type: "floor_tile",      label: "Floor Tile",     multi: false, options: [
      { key: "carrara_marble",  label: "Carrara Marble Look",   swatch: "#E8E4DC" },
      { key: "large_grey",      label: "Large Format Grey",     swatch: "#9EA4A8" },
      { key: "hex_white",       label: "White Hex Mosaic",      swatch: "#F0EFEB" },
    ]},
    { type: "shower_tile",     label: "Shower Tile",    multi: false, options: [
      { key: "subway_white",    label: "White Subway",          swatch: "#F2F0EB" },
      { key: "vertical_stack",  label: "Vertical Stack",        swatch: "#E0DDD4" },
      { key: "moroccan",        label: "Moroccan Pattern",      swatch: "#C8C0B0" },
    ]},
    { type: "vanity",          label: "Vanity Style",   multi: false, options: [
      { key: "shaker_white",    label: "Shaker White",          swatch: "#F0EDE8" },
      { key: "modern_grey",     label: "Modern Grey",           swatch: "#888E94" },
      { key: "wood_tone",       label: "Natural Wood Tone",     swatch: "#A07850" },
    ]},
    { type: "fixture_finish",  label: "Fixture Finish", multi: false, options: [
      { key: "matte_black",     label: "Matte Black",           swatch: "#2A2A2A" },
      { key: "brushed_nickel",  label: "Brushed Nickel",        swatch: "#9EA4A8" },
      { key: "polished_chrome", label: "Polished Chrome",       swatch: "#C8CDD4" },
      { key: "warm_gold",       label: "Warm Gold",             swatch: "#C8A84B" },
    ]},
  ],
  "bedroom_2" => [
    { type: "flooring",   label: "Flooring",   multi: false, options: [
      { key: "hardwood_oak",  label: "Natural Oak Hardwood",  swatch: "#C8A97E" },
      { key: "lvp_ash",       label: "Ash Grey LVP",          swatch: "#9DA8A0" },
      { key: "carpet_oat",    label: "Warm Oat Carpet",       swatch: "#D4C8A8" },
    ]},
    { type: "wall_color", label: "Wall Color", multi: false, options: [
      { key: "white_classic", label: "Classic White",         swatch: "#F5F4EF" },
      { key: "blush",         label: "Soft Blush",            swatch: "#E8C8B8" },
      { key: "lavender",      label: "Lavender Mist",         swatch: "#C4BAD8" },
      { key: "sky_blue",      label: "Sky Blue",              swatch: "#A8C4D8" },
    ]},
  ],
  "bedroom_3" => [
    { type: "flooring",   label: "Flooring",   multi: false, options: [
      { key: "hardwood_oak",  label: "Natural Oak Hardwood",  swatch: "#C8A97E" },
      { key: "lvp_ash",       label: "Ash Grey LVP",          swatch: "#9DA8A0" },
      { key: "carpet_oat",    label: "Warm Oat Carpet",       swatch: "#D4C8A8" },
    ]},
    { type: "wall_color", label: "Wall Color", multi: false, options: [
      { key: "white_classic", label: "Classic White",         swatch: "#F5F4EF" },
      { key: "greige_warm",   label: "Warm Greige",           swatch: "#C4B8A4" },
      { key: "navy_deep",     label: "Deep Navy",             swatch: "#1C2C4A" },
      { key: "forest_green",  label: "Forest Green",          swatch: "#3A5A44" },
    ]},
  ],
  "bathroom_2" => [
    { type: "floor_tile",     label: "Floor Tile",     multi: false, options: [
      { key: "carrara_marble",  label: "Carrara Marble Look",   swatch: "#E8E4DC" },
      { key: "large_grey",      label: "Large Format Grey",     swatch: "#9EA4A8" },
      { key: "hex_white",       label: "White Hex Mosaic",      swatch: "#F0EFEB" },
    ]},
    { type: "vanity",          label: "Vanity Style",   multi: false, options: [
      { key: "shaker_white",    label: "Shaker White",          swatch: "#F0EDE8" },
      { key: "modern_grey",     label: "Modern Grey",           swatch: "#888E94" },
      { key: "wood_tone",       label: "Natural Wood Tone",     swatch: "#A07850" },
    ]},
    { type: "fixture_finish",  label: "Fixture Finish", multi: false, options: [
      { key: "matte_black",     label: "Matte Black",           swatch: "#2A2A2A" },
      { key: "brushed_nickel",  label: "Brushed Nickel",        swatch: "#9EA4A8" },
      { key: "polished_chrome", label: "Polished Chrome",       swatch: "#C8CDD4" },
      { key: "warm_gold",       label: "Warm Gold",             swatch: "#C8A84B" },
    ]},
  ],
  "flex_room" => [
    { type: "flooring",   label: "Flooring",   multi: false, options: [
      { key: "hardwood_oak",  label: "Natural Oak Hardwood",  swatch: "#C8A97E" },
      { key: "lvp_ash",       label: "Ash Grey LVP",          swatch: "#9DA8A0" },
      { key: "carpet_oat",    label: "Warm Oat Carpet",       swatch: "#D4C8A8" },
    ]},
    { type: "wall_color", label: "Wall Color", multi: false, options: [
      { key: "white_classic", label: "Classic White",         swatch: "#F5F4EF" },
      { key: "greige_warm",   label: "Warm Greige",           swatch: "#C4B8A4" },
      { key: "navy_deep",     label: "Deep Navy",             swatch: "#1C2C4A" },
      { key: "sage_soft",     label: "Soft Sage",             swatch: "#8FA58E" },
    ]},
  ],
  "kitchen" => [
    { type: "cabinet_style",  label: "Cabinet Style",  multi: false, options: [
      { key: "shaker",          label: "Shaker",                swatch: "#E8E4DC" },
      { key: "flat_panel",      label: "Flat Panel",            swatch: "#D4D0C8" },
      { key: "raised_panel",    label: "Raised Panel",          swatch: "#C8BEA8" },
    ]},
    { type: "cabinet_color",  label: "Cabinet Color",  multi: false, options: [
      { key: "alpine_white",    label: "Alpine White",          swatch: "#F2EFE8" },
      { key: "greige",          label: "Soft Greige",           swatch: "#C4B8A4" },
      { key: "hale_navy",       label: "Hale Navy",             swatch: "#2A3A50" },
      { key: "charcoal",        label: "Charcoal",              swatch: "#3A3A3A" },
    ]},
    { type: "countertop",     label: "Countertop",     multi: false, options: [
      { key: "calacatta_quartz",label: "Calacatta Gold Quartz", swatch: "#E8E0CC" },
      { key: "carrara_quartz",  label: "Carrara Quartz",        swatch: "#E4E0D8" },
      { key: "quartz_black",    label: "Midnight Quartz",       swatch: "#2A2A2C" },
      { key: "butcher_block",   label: "Butcher Block",         swatch: "#B88850" },
    ]},
    { type: "backsplash",     label: "Backsplash",     multi: false, options: [
      { key: "subway_gloss",    label: "White Subway Gloss",    swatch: "#F0EFEB" },
      { key: "zellige",         label: "Zellige White",         swatch: "#EAE8E0" },
      { key: "matte_grey",      label: "Matte Grey",            swatch: "#9EA4A8" },
      { key: "hex_mosaic",      label: "White Hex Mosaic",      swatch: "#ECEAE4" },
    ]},
    { type: "hardware",       label: "Hardware",       multi: false, options: [
      { key: "matte_black",     label: "Matte Black",           swatch: "#2A2A2A" },
      { key: "brushed_nickel",  label: "Brushed Nickel",        swatch: "#9EA4A8" },
      { key: "warm_gold",       label: "Warm Gold",             swatch: "#C8A84B" },
      { key: "chrome",          label: "Polished Chrome",       swatch: "#C8CDD4" },
    ]},
  ],
  "living_room" => [
    { type: "flooring",   label: "Flooring",           multi: false, options: [
      { key: "hardwood_oak",    label: "Natural Oak Hardwood",  swatch: "#C8A97E" },
      { key: "lvp_ash",         label: "Ash Grey LVP",          swatch: "#9DA8A0" },
      { key: "carpet_oat",      label: "Warm Oat Carpet",       swatch: "#D4C8A8" },
    ]},
    { type: "wall_color", label: "Wall Color",         multi: false, options: [
      { key: "white_classic",   label: "Classic White",         swatch: "#F5F4EF" },
      { key: "warm_white",      label: "Warm White",            swatch: "#F0EAE0" },
      { key: "greige_warm",     label: "Warm Greige",           swatch: "#C4B8A4" },
      { key: "slate_blue",      label: "Slate Blue",            swatch: "#6A7F9A" },
    ]},
    { type: "fireplace",  label: "Fireplace Surround", multi: false, options: [
      { key: "standard",        label: "Standard Surround",     swatch: "#E8E0D0" },
      { key: "floor_to_ceiling",label: "Floor-to-Ceiling Tile", swatch: "#9EA4A8" },
      { key: "shiplap",         label: "Shiplap Surround",      swatch: "#F0EDEA" },
    ]},
  ],
}
```

---

## Files to Create

```
app/lib/demo_data.rb                              # ROOMS, FAMILY, HOME, DESIGN_STYLES, SELECTIONS constants
app/assets/images/design/styles/                  # 5 downloaded Unsplash images (style_*.jpg)

db/migrate/*_add_gems_design_session.rb           # design_sessions table
db/migrate/*_create_room_plans.rb                 # room_plans table
db/migrate/*_create_design_selections.rb          # design_selections table
db/migrate/*_create_draft_emails.rb               # draft_emails table
db/migrate/*_update_chat_messages.rb              # add message_type, component_type
db/migrate/*_remove_approved_render_from_leads.rb

app/models/design_session.rb                      # includes AASM, helpers
app/models/room_plan.rb
app/models/design_selection.rb
app/models/draft_email.rb

app/services/companion_llm.rb                     # wraps anthropic gem, builds per-state prompts
app/services/design_flow.rb                       # orchestration: current state → next component + LLM call

app/controllers/selections_controller.rb          # handles component interaction POSTs

app/views/chat_components/
  _room_purpose.html.erb                          # flex room purpose buttons
  _occupant_selector.html.erb                     # bedroom occupant assignment
  _style_picker.html.erb                          # design style image grid
  _option_selector.html.erb                       # selection tiles (flooring, wall color, etc.)
  _progress_card.html.erb                         # between-room transition card
  _summary_card.html.erb                          # full selections review
  _email_draft.html.erb                           # off-topic → draft email card

app/views/home/
  _design_brief.html.erb                          # left panel: property + family + progress

app/javascript/controllers/selection_controller.js  # handles all component interactions
```

## Files to Modify

```
Gemfile                                    # add aasm, anthropic
app/models/lead.rb                         # has_one :design_session
app/controllers/leads_controller.rb        # create design_session on lead create
app/controllers/messages_controller.rb     # route through DesignFlow instead of scripted_answer
app/controllers/home_controller.rb         # load @session, auto-post welcome if new
config/routes.rb                           # add selections resource, remove approval resource
app/views/home/show.html.erb               # replace companion-main with design_brief partial
app/javascript/controllers/companion_controller.js  # handle component_html in responses
```

## Files to Delete

```
app/controllers/approvals_controller.rb
app/views/home/message.html.erb            # only if no longer needed after refactor
```

---

## Phase Implementation Order

### Phase 0 — Gems & Migrations
1. Add `aasm`, `anthropic` to Gemfile, run `bundle install`
2. Run all migrations
3. Update `Lead` with `has_one :design_session`

### Phase 1 — Catalog & Services
1. Create `app/lib/demo_data.rb` with all constants
2. Download Unsplash style images to `app/assets/images/design/styles/`
3. Create `DesignSession` model with full AASM config and helper methods
4. Create `RoomPlan`, `DesignSelection`, `DraftEmail` models
5. Create `CompanionLlm` service
6. Create `DesignFlow` orchestration service

### Phase 2 — Controllers & Routes
1. Update routes (add selections, remove approval)
2. Delete `ApprovalsController`
3. Create `SelectionsController`
4. Refactor `MessagesController` to go through `DesignFlow`
5. Update `HomeController` to load session, trigger welcome

### Phase 3 — Chat Components (partials)
1. `_option_selector.html.erb`
2. `_room_purpose.html.erb`
3. `_occupant_selector.html.erb`
4. `_style_picker.html.erb`
5. `_progress_card.html.erb`
6. `_email_draft.html.erb`
7. `_summary_card.html.erb`

### Phase 4 — Left Panel & Layout
1. Create `_design_brief.html.erb`
2. Update `show.html.erb` — replace companion-main content with design_brief partial
3. CSS updates for new component styles in `application.css`

### Phase 5 — Stimulus
1. Update `companion_controller.js` to handle `component_html` in JSON responses
2. Create `selection_controller.js` for all component interactions
3. Wire all component partials to Stimulus actions

### Phase 6 — Polish & Build
1. Rebuild Tailwind CSS
2. End-to-end smoke test of full flow
3. Verify mobile tab bar still works with new left panel content

---

## Key Implementation Notes

### PATH for all commands
```bash
export PATH="/Users/bryansaxon/.asdf/installs/ruby/4.0.5/bin:/opt/homebrew/opt/postgresql@17/bin:$PATH"
```

### JSON response shape (both controllers must return this)
```json
{
  "message": "...",
  "component_html": "<div>...</div>",
  "component_type": "option_selector",
  "state": "designing",
  "rooms_complete": 2,
  "total_rooms": 8
}
```
`component_html` is null when there's no interactive component (pure text message).

### Companion Stimulus: handling component_html
```js
.then(data => {
  typingEl.remove()
  this.appendCompanionBubble(data.message)
  if (data.component_html) this.appendComponent(data.component_html)
  this.scrollToBottom()
  this._notifyIfHidden()
  if (data.rooms_complete !== undefined) this.updateProgress(data.rooms_complete, data.total_rooms)
})
```

### LLM system prompt structure (per state)
Every prompt starts with: who the family is, what home they're buying, what state we're in, what just happened, what a good response looks like, and hard constraints (never off-topic without flagging, never recommend a specific choice, always warm, 1–3 sentences, never mention being an AI, never mention being Claude).

### Design meeting date
```ruby
def next_design_meeting_date
  today = Date.today
  days = (3 - today.wday) % 7
  days = 7 if days.zero?
  (today + days).strftime("%A, %B %-d")  # e.g. "Wednesday, July 8"
end
```

### Unsplash image download (run once during setup)
```bash
mkdir -p app/assets/images/design/styles
curl -L "https://source.unsplash.com/featured/800x600/?interior,contemporary,minimal,living+room" -o app/assets/images/design/styles/style_contemporary.jpg
curl -L "https://source.unsplash.com/featured/800x600/?interior,modern,bold,bedroom" -o app/assets/images/design/styles/style_modern.jpg
curl -L "https://source.unsplash.com/featured/800x600/?interior,traditional,classic,warm,wood" -o app/assets/images/design/styles/style_traditional.jpg
curl -L "https://source.unsplash.com/featured/800x600/?farmhouse,interior,shiplap,white,rustic" -o app/assets/images/design/styles/style_farmhouse.jpg
curl -L "https://source.unsplash.com/featured/800x600/?transitional,interior,neutral,elegant" -o app/assets/images/design/styles/style_transitional.jpg
```
