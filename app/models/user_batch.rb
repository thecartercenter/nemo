class UserBatch < ActiveRecord::Base
  attr_reader :created_users
  
  def create_users(mission)
    @created_users = []
    transaction do
      users.each do |u|
        name, email, phone = u.split(/,|\t/).collect{|x| x.strip}
        user = User.new_with_login_and_password(:name => name, :email => email, :phone => phone, 
          :login => User.suggest_login(name), :reset_password_method => "print")
        user.assignments.build(:mission_id => mission.id, :role_id => Role.lowest.id, :active => true)
        user.save!
        @created_users << user
      end
    end
  end
end
