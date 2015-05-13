FactoryGirl.define do
  factory :questioning do
    question
    form
    parent { form.root_group }
    type "Questioning"
    mission { form.mission }
  end
end
