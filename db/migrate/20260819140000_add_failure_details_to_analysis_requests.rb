class AddFailureDetailsToAnalysisRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :analysis_requests, :automatic_retry_count, :integer, default: 0, null: false
    add_column :analysis_requests, :recoverable_failure, :boolean, default: false, null: false
    add_column :analysis_requests, :failure_message, :text
  end
end
