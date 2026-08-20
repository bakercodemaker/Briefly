require "test_helper"

class WorkbenchAccessTest < ActionDispatch::IntegrationTest
  test "public visitors can see the Demo Library entry but not the Personal Workspace" do
    get "/"

    assert_response :success
    assert_select "h1", "A better way to catch up."
    assert_select "a[href='/demo']", "Explore the Demo Library"

    get "/workspace"

    assert_redirected_to "/access"
  end

  test "the configured owner password unlocks the Personal Workspace" do
    with_owner_password("a private test password") do
      post "/access", params: { password: "a private test password" }

      assert_redirected_to "/workspace"

      follow_redirect!

      assert_response :success
      assert_select "h1", "Read with focus."
    end
  end

  test "an incorrect owner password does not unlock the Personal Workspace" do
    with_owner_password("a private test password") do
      post "/access", params: { password: "incorrect" }

      assert_response :unprocessable_entity
      assert_select "p", "That password does not unlock the Personal Workspace."
    end
  end

  test "the Demo Library is public and has no source submission form" do
    get "/demo"

    assert_response :success
    assert_select "h1", "A public window into the finished reading experience."
    assert_select "form", count: 0
  end
end
