require 'digest/sha2'

class CreateUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :language_id
      t.integer :role_id
      t.integer :location_id
      t.string :phone
      t.boolean :is_mobile_phone
      t.boolean :is_active
      t.string :password_salt
      t.string :crypted_password
      t.string :single_access_token
      t.string :perishable_token
      t.string :persistence_token

      t.timestamps
    end

    add_index(:users, [:login], :unique => true)
  end

  def self.down
    drop_table :users
  end
end
