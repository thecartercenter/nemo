FactoryGirl.define do
  trait :deleted do
    # Known issue in Rails 5.2: cannot directly create a record in deleted state
    # Must destroy it in callback
    # https://github.com/ActsAsParanoid/acts_as_paranoid#known-issues-with-rails-52
    after(:create, &:destroy)
  end
end
