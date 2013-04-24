FactoryGirl.define do
  factory :form do
    name { Random.words(2) }
    association :type, :factory => :form_type
    mission { get_mission }
  end
end