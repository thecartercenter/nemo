FactoryGirl.define do
  factory :report, :class => 'Report::Report' do
    mission { get_mission }

    factory :standard_form_report, class: 'Report::StandardFormReport' do
      form
    end
  end
end