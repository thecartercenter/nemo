FactoryGirl.define do
  factory :operation do
    creator factory: :user
    sequence(:details) { |n| "Operation ##{n}" }
    job_class TabularImportOperationJob
  end
end
