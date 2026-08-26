class CreateBriefs < ActiveRecord::Migration[8.1]
  def change
    create_table :briefs do |t|
      t.references :analysis_request, null: false, foreign_key: true, index: { unique: true }
      t.string :source_url, null: false
      t.string :source_title, null: false
      t.string :source_channel, null: false
      t.date :published_on, null: false
      t.integer :duration_seconds, null: false
      t.string :output_language, null: false
      t.text :content_markdown, null: false
      t.json :structured_content, null: false
      t.json :key_conclusions, null: false

      t.timestamps
    end
  end
end
