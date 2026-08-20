class AllowCancelledAnalysisRequests < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :analysis_requests, name: "analysis_requests_lifecycle_state"
    add_check_constraint :analysis_requests,
      "lifecycle_state IN ('queued', 'processing', 'completed', 'failed', 'cancelled')",
      name: "analysis_requests_lifecycle_state"
  end
end
