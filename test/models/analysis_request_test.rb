require "test_helper"

class AnalysisRequestTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { AnalysisRequest.delete_all }
  teardown { AnalysisRequest.delete_all }

  test "only one queued or processing request can reserve active capacity" do
    assert AnalysisRequest.reserve_active_request_slot { AnalysisRequest.create!(source_url: "https://youtu.be/one") }
    assert_not AnalysisRequest.reserve_active_request_slot { AnalysisRequest.create!(source_url: "https://youtu.be/two") }
    assert_equal 1, AnalysisRequest.active.count
  end
end
