class DesignRender < ApplicationRecord
  belongs_to :design_session
  has_one_attached :image

  STATUSES = %w[pending deferred generating complete failed].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :complete,  -> { where(status: "complete") }
  scope :deferred,  -> { where(status: "deferred") }
end
