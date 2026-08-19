class Brief < ApplicationRecord
  belongs_to :analysis_request

  validates :source_url, :source_title, :source_channel, :published_on, :duration_seconds, :output_language, :content_markdown, presence: true
  validates :structured_content, :key_conclusions, presence: true
  before_update :prevent_changes

  private

  def prevent_changes
    errors.add(:base, "Generated Briefs cannot be changed.")
    throw :abort
  end
end
