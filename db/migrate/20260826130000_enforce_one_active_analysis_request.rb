class EnforceOneActiveAnalysisRequest < ActiveRecord::Migration[8.1]
  def up
    active_request_ids = select_values(<<~SQL)
      SELECT id
      FROM analysis_requests
      WHERE archived_at IS NULL AND lifecycle_state IN ('queued', 'processing')
      ORDER BY CASE lifecycle_state WHEN 'processing' THEN 0 ELSE 1 END, created_at, id
    SQL

    if active_request_ids.many?
      execute <<~SQL
        UPDATE analysis_requests
        SET lifecycle_state = 'cancelled',
            recoverable_failure = FALSE,
            failure_message = 'Cancelled during the one-active-request upgrade.'
        WHERE id IN (#{active_request_ids.drop(1).join(', ')})
      SQL
    end

    add_column :analysis_requests, :active_slot, :integer
    execute "UPDATE analysis_requests SET active_slot = 1 WHERE archived_at IS NULL AND lifecycle_state IN ('queued', 'processing')"
    add_index :analysis_requests, :active_slot, unique: true, name: "index_one_active_analysis_request"
  end

  def down
    remove_index :analysis_requests, name: "index_one_active_analysis_request"
    remove_column :analysis_requests, :active_slot
  end
end
