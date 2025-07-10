class CreateApiKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :encrypted_key

      t.timestamps
    end
  end
end
