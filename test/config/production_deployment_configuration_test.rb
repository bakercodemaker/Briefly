require "test_helper"
require "yaml"

class ProductionDeploymentConfigurationTest < ActiveSupport::TestCase
  test "the Render Blueprint keeps secrets outside the repository and initializes the public demo" do
    blueprint = YAML.safe_load_file(Rails.root.join("render.yaml"))
    service = blueprint.fetch("services").sole

    assert_equal "web", service.fetch("type")
    assert_equal "ruby", service.fetch("runtime")
    assert_equal "free", service.fetch("plan")
    assert_equal "bin/render-build.sh", service.fetch("buildCommand")
    assert_equal "bundle exec rails server -b 0.0.0.0 -p $PORT", service.fetch("startCommand")
    assert_equal "/up", service.fetch("healthCheckPath")
    assert_equal "bin/rails db:seed", service.fetch("initialDeployHook")

    secret_keys = service.fetch("envVars").select { |variable| variable["sync"] == false }.pluck("key")
    assert_equal %w[DATABASE_URL GEMINI_API_KEY OWNER_PASSWORD RAILS_MASTER_KEY].sort, secret_keys.sort

    build_script = Rails.root.join("bin/render-build.sh").read
    assert_match(/yarn install --frozen-lockfile/, build_script)
    assert_match(/bundle exec rails assets:precompile/, build_script)
    assert_match(/bundle exec rails db:prepare/, build_script)
    assert_no_match(/schema:load:queue/, build_script)
    assert_no_match(/DISABLE_DATABASE_ENVIRONMENT_CHECK/, build_script)
    assert_path_exists Rails.root.join("db/migrate/20260821150000_initialize_solid_queue_safely.rb")
  end

  test "production enforces HTTPS, host authorization, and a restrictive CSP" do
    production = Rails.root.join("config/environments/production.rb").read
    csp = Rails.root.join("config/initializers/content_security_policy.rb").read
    session_store = Rails.root.join("config/initializers/session_store.rb").read

    assert_match(/config\.force_ssl = true/, production)
    assert_match(/config\.hosts = allowed_hosts/, production)
    assert_match(/policy\.default_src :self/, csp)
    assert_match(/policy\.object_src :none/, csp)
    assert_match(/expire_after: 12\.hours/, session_store)
    assert_match(/httponly: true/, session_store)
    assert_match(/same_site: :lax/, session_store)
  end

  test "CI runs the documented TypeScript check" do
    workflow = Rails.root.join(".github/workflows/ci.yml").read

    assert_match(/yarn typecheck/, workflow)
  end

  test "all Rails production stores share the external database URL" do
    original_database_url = ENV["DATABASE_URL"]
    ENV["DATABASE_URL"] = "postgresql://briefly:password@example.test/briefly"

    production = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/database.yml")).fetch("production")

    assert_equal %w[cable cache primary queue], production.keys.sort
    assert production.values.all? { |configuration| configuration.fetch("url") == ENV.fetch("DATABASE_URL") }
  ensure
    ENV["DATABASE_URL"] = original_database_url
  end
end
