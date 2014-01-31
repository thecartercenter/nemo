FactoryGirl.define do
  factory :report, :class => 'Report::Report' do
    mission { get_mission }
  end
end