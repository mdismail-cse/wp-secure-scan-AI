class AddProviderToApiKeys < ActiveRecord::Migration[7.2]
  def change
    add_column :api_keys, :provider, :string, default: 'openai'
  end
end
