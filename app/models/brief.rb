class Brief < ApplicationRecord
  belongs_to :analysis_request

  scope :completed, -> { joins(:analysis_request).where(analysis_requests: { lifecycle_state: "completed", archived_at: nil }) }
  scope :personal, -> { where(publicly_visible: false) }
  scope :public_demo, -> { completed.where(publicly_visible: true) }
  scope :archived, -> { personal.joins(:analysis_request).where.not(analysis_requests: { archived_at: nil }) }

  def self.completed_by_channel
    personal.completed.order(created_at: :desc).group_by(&:source_channel)
  end

  validates :source_url, :source_title, :source_channel, :published_on, :duration_seconds, :output_language, :content_markdown, presence: true
  validates :structured_content, :key_conclusions, presence: true
  validates :key_conclusions, length: { in: 5..10 }
  before_update :prevent_changes

  private

  def prevent_changes
    errors.add(:base, "Generated Briefs cannot be changed.")
    throw :abort
  end
end
