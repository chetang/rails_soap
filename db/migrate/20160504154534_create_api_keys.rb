class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id
      t.string :access_token
      t.string :company
      t.datetime :expired_at
      t.boolean :is_active
      t.timestamps
    end
  end
end
