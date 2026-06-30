class DesignSelection < ApplicationRecord
  belongs_to :design_session
  validates :room_key, :selection_type, :option_key, :option_label, presence: true
end
