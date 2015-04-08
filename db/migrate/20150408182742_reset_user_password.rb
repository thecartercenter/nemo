class ResetUserPassword < ActiveRecord::Migration
  def change
    User.all.each do |user|
      user.password = User.random_password
      user.save
    end
  end
end
