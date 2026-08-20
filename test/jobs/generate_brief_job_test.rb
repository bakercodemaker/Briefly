require "test_helper"

class GenerateBriefJobTest < ActiveJob::TestCase
  test "uses the real Gemini adapter when no test override is configured" do
    assert_instance_of GeminiAdapter, GenerateBriefJob.new.send(:gemini_adapter)
  end
end
