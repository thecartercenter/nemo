FactoryGirl.define do
  factory :form do
    name { "Form #{rand(1000000)}" }
    association :type, :factory => :form_type
    mission { get_mission }
  end
end