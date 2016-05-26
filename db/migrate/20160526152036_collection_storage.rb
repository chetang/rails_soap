class CollectionStorage < ActiveRecord::Migration
  def change
    create_table :collection_storages do |t|
      t.integer :user_id
      t.string :key
      t.string :collection
      t.string :company
      t.timestamps
    end
  end
end
