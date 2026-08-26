require "test_helper"

class LocalQueueRuntimeTest < ActiveSupport::TestCase
  class DurableQueueProbeJob < ApplicationJob
    def perform; end
  end

  test "Solid Queue persists an enqueued job in the application database" do
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue

    assert_difference("SolidQueue::Job.count", 1) do
      DurableQueueProbeJob.perform_later
    end
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end
end
