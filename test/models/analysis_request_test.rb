require "test_helper"

class AnalysisRequestTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { AnalysisRequest.delete_all }
  teardown { AnalysisRequest.delete_all }

  test "only three concurrent requests can reserve active capacity" do
    start = Queue.new
    results = 4.times.map do |index|
      Thread.new do
        start.pop
        AnalysisRequest.connection_pool.with_connection do
          AnalysisRequest.reserve_active_request_slot do
            AnalysisRequest.create!(source_url: "https://youtu.be/concurrent#{index}")
            true
          end
        end
      end
    end

    4.times { start << true }
    results = results.map(&:value)

    assert_equal 3, results.count(true)
    assert_equal 3, AnalysisRequest.active.count
  end
end
