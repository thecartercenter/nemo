def get_user
  User.find_by_login("test") || FactoryGirl.create(:user)
end

FactoryGirl.define do
  factory :user do
    login "test"
    name "Test Test"
    reset_password_method "print"
    password "kkkdddkkk"
    password_confirmation "kkkdddkkk"
    phone "+15558881212"
    
    after(:build) do |user|
      Role.generate
      user.assignments.build(:mission => get_mission, :active => true, :role => Role.highest)
    end
  end
end