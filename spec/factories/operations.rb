FactoryGirl.define do
  factory :operation do
    creator factory: :user
    sequence(:details) { |n| "Operation ##{n}" }
    mission { get_mission }
    job_class TabularImportOperationJob
  end
end
