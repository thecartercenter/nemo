class UserBatch < ActiveRecord::Base
  attr_reader :created_users
  
  def create_users
    @created_users = []
    transaction do
      users.each do |u|
        bits = u.split(" ")
        email = bits.pop
        name = bits.join(" ")
        user = User.new_with_login_and_password(:name => name, :email => email, 
          :role_id => Role.lowest.id, :language_id => Language.english.id, :login => User.suggest_login(name))
        user.save!
        @created_users << user
      end
    end
  end
end
