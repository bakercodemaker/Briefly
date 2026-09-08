require "test_helper"

class ActiveStorageConfigurationTest < ActiveSupport::TestCase
  test "the test Active Storage service is configured" do
    assert Rails.root.join("config/storage.yml").file?
    assert_instance_of ActiveStorage::Service::DiskService, ActiveStorage::Blob.service
  end
end
