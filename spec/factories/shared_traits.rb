FactoryGirl.define do
  trait :deleted do
    deleted_at { Time.now }
  end
end
