class AddColumnsToUser < ActiveRecord::Migration
  def change
    add_column :users, :odin_username, :string
    add_column :users, :odin_password, :string
    add_column :users, :odin_active, :boolean, default: true
    add_column :users, :ld_username, :string
    add_column :users, :ld_password, :string
    add_column :users, :ld_active, :boolean, default: true
  end
end
