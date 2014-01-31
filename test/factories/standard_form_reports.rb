FactoryGirl.define do
  factory :standard_form_report, :class => 'Report::StandardFormReport', :parent => :report do
    form
  end
end