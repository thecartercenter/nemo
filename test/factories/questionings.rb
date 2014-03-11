FactoryGirl.define do
  factory :questioning do
    question
    form
    mission {get_mission}
  end
end