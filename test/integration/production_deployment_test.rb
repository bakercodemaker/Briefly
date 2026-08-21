require "test_helper"
class ProductionDeploymentTest < ActionDispatch::IntegrationTest
  test "the public entry point sets a cold-start expectation" do
    get root_path

    assert_response :success
    assert_select "p", /may take about a minute to wake after inactivity/i
  end
end
