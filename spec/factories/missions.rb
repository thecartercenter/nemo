def get_mission
  Mission.order(:created_at).first || create(:mission)
end

FactoryGirl.define do
  sequence(:name) { |n| "Mission #{n}" }

  factory :mission do
    transient do
      with_user nil
      role_name :coordinator
    end

    name
    setting { build(:setting) }

    after(:create) do |mission, evaluator|
      mission.assignments.create(user: evaluator.with_user, role: evaluator.role_name.to_s) if evaluator.with_user
    end
  end
end
