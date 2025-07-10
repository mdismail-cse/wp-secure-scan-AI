class CreateVulnerabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :vulnerabilities do |t|
      t.references :scan, null: false, foreign_key: true
      t.string :file_path
      t.integer :line_number
      t.string :vulnerability_type
      t.string :severity
      t.text :description
      t.text :code_snippet
      t.text :ai_explanation
      t.text :fix_suggestion

      t.timestamps
    end
    add_index :vulnerabilities, :severity
  end
end
