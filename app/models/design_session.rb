class DesignSession < ApplicationRecord
  include AASM

  belongs_to :lead
  has_many :room_plans,       dependent: :destroy
  has_many :design_selections, dependent: :destroy
  has_many :draft_emails,     dependent: :destroy

  aasm column: :aasm_state, whiny_persistence: false do
    state :welcome, initial: true
    state :household_review
    state :room_planning
    state :style_selection
    state :designing
    state :summary_review
    state :complete

    event :show_household_recap do transitions from: :welcome,           to: :household_review end
    event :begin_planning       do transitions from: %i[welcome household_review], to: :room_planning end
    event :finish_planning      do transitions from: :room_planning,  to: :style_selection end
    event :finish_styles        do transitions from: :style_selection, to: :designing      end
    event :finish_designing     do transitions from: :designing,      to: :summary_review  end
    event :finish_summary       do transitions from: :summary_review,  to: :complete       end
  end

  def effective_family
    base = DemoData::FAMILY.dup.map { |p| p.dup }
    return base if custom_family_json.blank?
    custom = JSON.parse(custom_family_json)
    base + custom.map { |p| p.transform_keys(&:to_sym) }
  rescue
    DemoData::FAMILY
  end

  def add_family_member(attrs)
    current = custom_family_json.present? ? JSON.parse(custom_family_json) : []
    current << attrs.transform_keys(&:to_s)
    update!(custom_family_json: current.to_json)
  end

  def design_styles_array
    return [] if design_styles.blank?
    JSON.parse(design_styles) rescue []
  end

  def design_styles_array=(arr)
    self.design_styles = arr.to_json
  end

  def rooms_in_order
    DemoData::ROOMS
  end

  def current_room_config
    DemoData.room(current_room) if current_room.present?
  end

  def current_selection_config
    return nil unless current_room.present?
    selections = DemoData.selections_for(current_room)
    selections[current_selection_index]
  end

  def assigned_occupant_keys
    room_plans.where.not(occupants: nil).flat_map { |rp| JSON.parse(rp.occupants) rescue [] }.uniq
  end

  def all_rooms_planned?
    planned_keys = room_plans.where(complete: true).or(room_plans.where(skipped: true)).pluck(:room_key)
    rooms_needing_planning.all? { |r| planned_keys.include?(r[:key]) }
  end

  def next_unplanned_room
    planned_keys = room_plans.pluck(:room_key)
    rooms_needing_planning.find { |r| !planned_keys.include?(r[:key]) }
  end

  def rooms_needing_planning
    DemoData::ROOMS.select { |r| r[:ask_purpose] || r[:ask_occupants] }
  end

  def rooms_complete_count
    designed_rooms = design_selections.pluck(:room_key).uniq
    DemoData::ROOMS.count { |r| room_fully_designed?(r[:key], designed_rooms) }
  end

  def room_fully_designed?(room_key, designed_rooms = nil)
    designed_rooms ||= design_selections.pluck(:room_key).uniq
    return false unless designed_rooms.include?(room_key)
    required = DemoData.selections_for(room_key).map { |s| s[:type] }
    filled = design_selections.where(room_key: room_key).pluck(:selection_type)
    (required - filled).empty?
  end

  def next_undesigned_room
    DemoData::ROOMS.find { |r| !room_fully_designed?(r[:key]) }
  end

  def pending_selections
    design_selections.where(pending: true)
  end

  def summary_by_room
    DemoData::ROOMS.filter_map do |room|
      sels = design_selections.where(room_key: room[:key]).order(:created_at)
      next if sels.empty?
      { room: room, selections: sels }
    end
  end

  def all_selections_made?
    DemoData::ROOMS.all? { |r| room_fully_designed?(r[:key]) }
  end
end
