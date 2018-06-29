class GenerateSmsAuthCodes < ActiveRecord::Migration[4.2]
  def up
    User.find_each do |user|
      auth_code = Random.alphanum(4)
      user.update_column(:sms_auth_code, auth_code)
    end
  end

  def down
    User.find_each do |user|
      user.update_column(:sms_auth_code, nil)
    end
  end
end
