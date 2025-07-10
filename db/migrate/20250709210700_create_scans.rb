class CreateScans < ActiveRecord::Migration[7.2]
  def change
    create_table :scans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plugin_name
      t.string :file_path
      t.string :status
      t.text :scan_results
      t.text :ai_analysis

      t.timestamps
    end
    add_index :scans, :status
  end
end
