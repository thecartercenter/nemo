class AddBooleanDefaults < ActiveRecord::Migration[4.2]
  def self.up
    bools = [
      {:table => "forms", :col => "is_published"},
      {:table => "languages", :col => "is_active"},
      {:table => "places", :col => "is_incomplete"},
      {:table => "questionings", :col => "required"},
      {:table => "questionings", :col => "hidden"},
      {:table => "question_types", :col => "phone_only"},
      {:table => "responses", :col => "reviewed"},
      {:table => "roles", :col => "location_required"},
      {:table => "users", :col => "active"},
      {:table => "users", :col => "is_mobile_phone"}
    ]
    bools.each do |bool|
      execute("alter table #{bool[:table]} alter #{bool[:col]} set default 0")
      execute("update #{bool[:table]} set #{bool[:col]}=0 where #{bool[:col]} is null")
    end
  end

  def self.down
  end
end
