require 'digest/sha2'

class CreateUsers < ActiveRecord::Migration
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
    salt = ActiveSupport::SecureRandom.base64(8)
    
    add_index(:users, [:login], :unique => true)
    
    # Create the administrators.
    u = User.new(:login => "tomsmyth", :first_name => "Thomas", :last_name => "Smyth", 
      :email => "tomsmyth@gmail.com", :role_id => Role.find(:first, :order => "level desc").id,
      :phone => "+14045832505", :is_mobile_phone => true, :is_active => true, 
      :language_id => Language.find_by_name("English").id)
    u.password = u.password_confirmation = 't1ckleME'
    u.save
  end

  def self.down
    drop_table :users
  end
end
