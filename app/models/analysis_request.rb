class AnalysisRequest < ApplicationRecord
  has_one :brief, dependent: :destroy
  LIFECYCLE_STATES = %w[queued processing completed failed].freeze
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com youtu.be].freeze

  validates :source_url, presence: true
  validates :lifecycle_state, inclusion: { in: LIFECYCLE_STATES }
  validate :source_url_is_a_public_youtube_video

  def recoverable_failure?
    failed? && recoverable_failure
  end

  def failed?
    lifecycle_state == "failed"
  end

  def retry_after_recoverable_failure!
    with_lock do
      return false unless recoverable_failure?

      update!(lifecycle_state: "queued", automatic_retry_count: 0, recoverable_failure: false, failure_message: nil)
      true
    end
  end

  private

  def source_url_is_a_public_youtube_video
    uri = URI.parse(source_url.to_s)

    unless uri.is_a?(URI::HTTP) && YOUTUBE_HOSTS.include?(uri.host&.downcase) && youtube_video_path?(uri)
      add_source_url_error
    end
  rescue URI::InvalidURIError
    add_source_url_error
  end

  def youtube_video_path?(uri)
    return uri.path.match?(%r{\A/[^/]+\z}) if uri.host&.downcase == "youtu.be"

    (uri.path == "/watch" && uri.query.to_s.split("&").any? { |parameter| parameter.match?(/\Av=.+/) }) ||
      uri.path.match?(%r{\A/(shorts|embed|live)/[^/]+\z})
  end

  def add_source_url_error
    errors.add(:source_url, "Enter a public YouTube video URL.")
  end
end
