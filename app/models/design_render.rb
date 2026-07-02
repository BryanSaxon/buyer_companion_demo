class DesignRender < ApplicationRecord
  belongs_to :design_session
  has_one_attached :image

  STATUSES = %w[pending generating complete failed].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :complete, -> { where(status: "complete") }
end
