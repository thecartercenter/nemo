def get_user
  u = FactoryGirl.create(:user)

  # set the mission to get_mission so that ability stuff will work
  u.save(:validate => false)

  return u
end

FactoryGirl.define do
  factory :user do
    ignore do
      role_name :coordinator
      mission { get_mission }
    end

    login { Random.letters(8) }
    name { Random.full_name }
    email { Random.letters(8) + '@example.com' }
    reset_password_method "print"
    password "password"
    password_confirmation "password"
    phone { Random.phone }
    pref_lang "en"
    login_count 1

    persistence_token { Authlogic::Random.hex_token }
    single_access_token { Authlogic::Random.friendly_token }
    perishable_token { Authlogic::Random.friendly_token }

    after(:build) do |user, evaluator|
      user.assignments.build(:mission => evaluator.mission, :role => evaluator.role_name.to_s)
    end
  end
end
