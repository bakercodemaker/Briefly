class RemovePublicVisibilityFromBriefs < ActiveRecord::Migration[8.1]
  def change
    remove_index :briefs, :publicly_visible if index_exists?(:briefs, :publicly_visible)
    remove_column :briefs, :publicly_visible, :boolean if column_exists?(:briefs, :publicly_visible)
  end
end
