class AddPublicVisibilityToBriefs < ActiveRecord::Migration[8.1]
  def change
    add_column :briefs, :publicly_visible, :boolean, default: false, null: false
    add_index :briefs, :publicly_visible
  end
end
