require "test_helper"
require "yaml"

class LocalRuntimeConfigurationTest < ActiveSupport::TestCase
  HOSTED_RUNTIME_PATHS = %w[
    render.yaml
    bin/render-build.sh
  ].freeze

  test "hosted runtime artifacts are retired" do
    HOSTED_RUNTIME_PATHS.each do |path|
      assert_not Rails.root.join(path).exist?, "#{path} should not remain in a local-only runtime"
    end
  end

  test "Docker Compose runs the local app without an external database service" do
    compose = YAML.safe_load_file(Rails.root.join("compose.yaml"))
    services = compose.fetch("services")

    assert_equal [ "web" ], services.keys
    assert_equal "Dockerfile.dev", services.fetch("web").fetch("build").fetch("dockerfile")
    assert_no_match(/DATABASE_URL|POSTGRES|NEON/i, services.fetch("web").to_s)
  end

  test "development image owns the Ruby and Rails runtime" do
    dockerfile = Rails.root.join("Dockerfile.dev").read
    entrypoint = Rails.root.join("entrypoint.dev.sh").read

    assert_match(/FROM ruby:4\.0\.5-slim/, dockerfile)
    assert_match(/bundle install/, dockerfile)
    assert_match(/yarn install --frozen-lockfile/, dockerfile)
    assert_match(/bin\/rails db:prepare/, entrypoint)
  end

  test "production configuration does not keep hosted deployment branches" do
    production = Rails.root.join("config/environments/production.rb").read

    assert_no_match(/Render|ALLOWED_HOSTS|assume_ssl|force_ssl/, production)
  end

  test "README documents the Docker local workflow as the supported runtime" do
    readme = Rails.root.join("README.md").read

    assert_match(/docker compose up --build/, readme)
    assert_match(/docker compose run --rm web bin\/rails test/, readme)
    assert_no_match(/Render|Neon|DATABASE_URL|Production deployment/i, readme)
  end
end
