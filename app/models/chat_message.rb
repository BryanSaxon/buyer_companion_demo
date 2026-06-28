class ChatMessage < ApplicationRecord
  belongs_to :lead

  validates :role, inclusion: { in: %w[user companion] }
  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
