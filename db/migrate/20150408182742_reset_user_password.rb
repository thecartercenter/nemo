class ResetUserPassword < ActiveRecord::Migration[4.2]
  def change
    # Standards have increased so we need to reset everyone's password.
    User.all.each do |user|
      user.password = user.password_confirmation = User.random_password
      user.save(validate: false)
    end
  end
end
