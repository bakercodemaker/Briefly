require "test_helper"

class WorkbenchAccessTest < ActionDispatch::IntegrationTest
  test "public visitors can see the private workspace entry but not the Personal Workspace" do
    get "/"

    assert_response :success
    assert_select "h1", "A better way to catch up."
    assert_select "a[href='/access']", "Unlock Personal Workspace"

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

  test "repeated failed unlock attempts are throttled" do
    with_owner_password("a private test password") do
      5.times do
        post "/access", params: { password: "incorrect" }
        assert_response :unprocessable_entity
      end

      post "/access", params: { password: "incorrect" }

      assert_response :too_many_requests
      assert_select "p", "Too many unlock attempts. Try again later."
    end
  end

  test "an idle owner session expires" do
    unlock_workspace

    travel 31.minutes do
      get "/workspace"
    end

    assert_redirected_to "/access"
  end

  test "an owner session expires after its absolute lifetime" do
    unlock_workspace

    travel 12.hours + 1.minute do
      get "/workspace"
    end

    assert_redirected_to "/access"
  end

  test "the Demo Library is public and has no source submission form" do
    get "/demo"

    assert_response :success
    assert_select "h1", "A public window into the finished reading experience."
    assert_select "form", count: 0
  end
end
