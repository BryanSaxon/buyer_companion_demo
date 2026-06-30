class RoomPlan < ApplicationRecord
  belongs_to :design_session

  validates :room_key, presence: true
  validates :room_key, uniqueness: { scope: :design_session_id }

  def occupants_array
    return [] if occupants.blank?
    JSON.parse(occupants) rescue []
  end

  def occupants_array=(arr)
    self.occupants = arr.to_json
  end

  def occupant_labels
    occupants_array.map { |k| DemoData.family_member(k)&.dig(:name) || k }.compact
  end

  def room_config
    DemoData.room(room_key)
  end
end
