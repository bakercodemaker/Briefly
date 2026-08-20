require "test_helper"

class DemoLibraryTest < ActionDispatch::IntegrationTest
  test "seeded public Briefs are visible to anonymous visitors" do
    Rails.application.load_seed

    get "/demo"

    assert_response :success
    assert_equal 3, Brief.public_demo.count
    assert_select "a[href=?]", demo_brief_path(Brief.public_demo.find_by!(source_title: "How to Speak So That People Want to Listen")) do
      assert_select "h3", "How to Speak So That People Want to Listen"
    end
  end

  test "an anonymous visitor reads only curated public Briefs" do
    public_brief = create_completed_brief(
      source_title: "How public libraries strengthen communities",
      source_channel: "Civic Learning",
      source_url: "https://www.youtube.com/watch?v=publicDemo",
      publicly_visible: true
    )
    create_completed_brief(
      source_title: "Private investment notes",
      source_channel: "Personal Research",
      source_url: "https://www.youtube.com/watch?v=privateBrief",
      publicly_visible: false
    )

    get "/demo"

    assert_response :success
    assert_select "h1", "A public window into the finished reading experience."
    assert_select "a[href=?]", "/demo/briefs/#{public_brief.id}" do
      assert_select "h3", "How public libraries strengthen communities"
    end
    assert_select "a", text: "Private investment notes", count: 0
    assert_select "form", count: 0

    get "/demo/briefs/#{public_brief.id}"

    assert_response :success
    assert_select "h1", "How public libraries strengthen communities"
    assert_select "a[href='https://www.youtube.com/watch?v=publicDemo']", count: 1
    assert_select "a", "Watch the original YouTube video"
    assert_select "p", /generated from the linked source/i
    assert_select "form", count: 0
  end

  test "an anonymous visitor cannot open a private Brief through the Demo Library" do
    private_brief = create_completed_brief(
      source_title: "Private investment notes",
      source_channel: "Personal Research",
      source_url: "https://www.youtube.com/watch?v=privateBrief",
      publicly_visible: false
    )

    get "/demo/briefs/#{private_brief.id}"

    assert_response :not_found
  end
end
