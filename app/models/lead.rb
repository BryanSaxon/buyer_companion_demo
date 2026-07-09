class Lead < ApplicationRecord
  has_many :chat_messages, dependent: :destroy
  has_one  :design_session, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :company, presence: true
  validates :email, presence: true, format: { with: /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ }

  def first_name_display
    first_name.to_s.strip.split(/\s+/).first || "there"
  end

  def org_name
    company.to_s.strip.presence || "Bucker Labs"
  end

  # Matching predefined builder for this lead's company (nil for legacy
  # free-text companies that predate the dropdown).
  def builder
    # Fully-qualified: inside an ActiveRecord model, a bare `Builder` resolves
    # to ActiveRecord::Associations::Builder, not our top-level registry.
    ::Builder.find_by_name(company)
  end

  # Logo asset path when the company matches a predefined builder, else nil.
  # Views fall back to org_initials when this is absent.
  def logo_path
    builder&.logo
  end

  def org_initials
    clean = org_name.gsub(/[^a-zA-Z0-9 ]/, " ").strip
    words = clean.split.reject(&:empty?)
    result = if words.size >= 2
      words[0][0].to_s + words[1][0].to_s
    elsif words.size == 1
      words[0][0].to_s + (words[0][1].to_s)
    end
    (result.presence || "BL").upcase
  end

  def self.find_or_initialize_from_params(params)
    existing = find_by(email: params[:email].to_s.strip.downcase)
    return existing if existing

    new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      company: params[:company],
      email: params[:email].to_s.strip.downcase
    )
  end
end
