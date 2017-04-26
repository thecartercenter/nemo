def get_user
  u = FactoryGirl.create(:user)

  # set the mission to get_mission so that ability stuff will work
  u.save(:validate => false)

  return u
end

def test_password
  "Password1"
end

FactoryGirl.define do
  factory :user do
    transient do
      role_name :coordinator
      mission { get_mission }
    end

    login { Random.letters(8) }
    sequence(:name) { |n| "A User #{n}" }
    email { Random.letters(8) + '@example.com' }
    reset_password_method "email"
    password { test_password }
    password_confirmation { test_password }
    phone { Random.phone_num }
    pref_lang "en"
    login_count 1

    persistence_token { Authlogic::Random.hex_token }
    perishable_token { Authlogic::Random.friendly_token }

    after(:build) do |user, evaluator|
      user.assignments.build(:mission => evaluator.mission, :role => evaluator.role_name.to_s)
    end
  end
end
