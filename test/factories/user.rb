def get_user
  u = User.find_by_login("test") || FactoryGirl.create(:user)
  
  # set the mission to get_mission so that ability stuff will work
  u.current_mission = get_mission
  u.save(:validate => false)
  
  return u
end

FactoryGirl.define do
  factory :user do
    ignore do
      role_name :coordinator
    end
    
    login {"test#{role_name}"}
    name {"Test #{role_name.capitalize}"}
    reset_password_method "print"
    password "password"
    password_confirmation "password"
    phone "+15558881212"
    pref_lang "en"
    
    persistence_token { Authlogic::Random.hex_token }
    single_access_token { Authlogic::Random.friendly_token }
    perishable_token { Authlogic::Random.friendly_token }
    
    after(:build) do |user, evaluator|
      user.assignments.build(:mission => get_mission, :active => true, :role => evaluator.role_name.to_s)
    end
  end
end