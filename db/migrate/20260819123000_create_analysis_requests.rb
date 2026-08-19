class CreateAnalysisRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :analysis_requests do |t|
      t.string :source_url, null: false
      t.string :lifecycle_state, null: false, default: "queued"

      t.timestamps
    end

    add_index :analysis_requests, :created_at
    add_check_constraint :analysis_requests,
      "lifecycle_state IN ('queued', 'processing', 'completed', 'failed')",
      name: "analysis_requests_lifecycle_state"
  end
end
