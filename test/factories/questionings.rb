FactoryGirl.define do
  factory :questioning do
    question
    form
    type "Questioning"
    mission {get_mission}
  end
end
