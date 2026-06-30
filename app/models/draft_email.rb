class DraftEmail < ApplicationRecord
  belongs_to :design_session
  validates :original_question, :subject, :body, presence: true
end
