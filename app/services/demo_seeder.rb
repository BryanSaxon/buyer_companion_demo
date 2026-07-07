module DemoSeeder
  # Creates (or recreates) the Harrison family design session in the completed,
  # post-design state. Called by db/seeds.rb and DemoController#reset.
  def self.seed_harrison_session(lead)
    session = lead.create_design_session!(
      aasm_state:               "complete",
      planning_complete:        true,
      style_selected:           true,
      summary_approved:         true,
      design_styles:            [ "farmhouse" ].to_json,
      custom_family_json:       DemoData::FAMILY.map { |p| p.transform_keys(&:to_s) }.to_json,
      current_room:             nil,
      current_selection_index:  0
    )

    seed_room_plans(session)
    seed_design_selections(session)

    session
  end

  private

  def self.seed_room_plans(session)
    plans = [
      { room_key: "master_bedroom",  purpose: "bedroom", occupants: %w[michael sarah], complete: true },
      { room_key: "bedroom_2",       purpose: "bedroom", occupants: %w[owen],           complete: true },
      { room_key: "bedroom_3",       purpose: "bedroom", occupants: %w[lily],            complete: true },
      { room_key: "bedroom_4",       purpose: "bedroom", occupants: %w[charlotte],       complete: true },
      { room_key: "bedroom_5",       purpose: "guest_room", occupants: [],               complete: true },
      { room_key: "master_bathroom", purpose: nil,       occupants: [],                  complete: true },
      { room_key: "bathroom_2",      purpose: nil,       occupants: [],                  complete: true },
      { room_key: "kitchen",         purpose: nil,       occupants: [],                  complete: true },
      { room_key: "living_room",     purpose: nil,       occupants: [],                  complete: true }
    ]

    plans.each do |plan|
      member_labels = plan[:occupants].map do |key|
        m = DemoData.family_member(key)
        m ? m[:name] : key.humanize
      end

      session.room_plans.create!(
        room_key:      plan[:room_key],
        purpose:       plan[:purpose],
        purpose_label: purpose_label_for(plan[:purpose]),
        occupants:     plan[:occupants].to_json,
        complete:      plan[:complete],
        skipped:       false
      )
    end
  end

  def self.seed_design_selections(session)
    now = Time.current
    DemoData::CONFIRMED_SELECTIONS.each do |sel|
      session.design_selections.create!(
        room_key:       sel[:room_key],
        selection_type: sel[:selection_type],
        option_key:     sel[:option_key],
        option_label:   sel[:option_label],
        pending:        false
      )
    end
  end

  def self.purpose_label_for(purpose)
    return nil if purpose.nil?
    DemoData::FLEX_PURPOSES.find { |p| p[:key] == purpose }&.dig(:label) || purpose.humanize
  end
end
