FactoryGirl.define do
  factory :qing_group do
    form
    parent { form.root_group }
    type "QingGroup"
    mission { form.mission }
    group_name "group"
    group_hint "hint"
    one_screen true
  end
end
