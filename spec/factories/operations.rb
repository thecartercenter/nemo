FactoryGirl.define do
  factory :operation do
    creator factory: :user
    sequence(:details) { |n| "Operation ##{n}" }
    job_started_at "2015-06-19 10:24:57"
    job_completed_at "2015-06-19 10:34:57"
    job_id "fbbe9bcf-4bae-438d-9733-34d368002f51"
    provider_job_id "123"
  end
end
