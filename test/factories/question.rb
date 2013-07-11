FactoryGirl.define do
  factory :question do
    name_en "Questo"
    code "questo"
    qtype_name "integer"
    mission { get_mission }
  end
end