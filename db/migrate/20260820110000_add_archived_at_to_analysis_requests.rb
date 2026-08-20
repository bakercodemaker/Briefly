class AddArchivedAtToAnalysisRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :analysis_requests, :archived_at, :datetime
    add_index :analysis_requests, :archived_at
  end
end
