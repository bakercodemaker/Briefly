require "test_helper"

class LocalRuntimeConfigurationTest < ActiveSupport::TestCase
  test "README presents the native local runtime" do
    readme = Rails.root.join("README.md").read

    assert_match(/native Rails, SQLite, and Solid Queue/i, readme)
    assert_match(/bin\/jobs start/, readme)
    assert_match(/GEMINI_API_KEY.*optional/i, readme)
    assert_match(/docs\/screenshots\/locked-workspace\.png/, readme)
    assert_match(/docs\/screenshots\/completed-brief\.png/, readme)
    assert_match(/docker compose/i, readme)
    assert_no_match(/Render|Neon|DATABASE_URL/i, readme)
  end
end
