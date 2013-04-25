def get_mission
  Mission.find_by_name("MissionWithSettings") || FactoryGirl.create(:mission)
end

FactoryGirl.define do
  factory :mission do
    name "MissionWithSettings"
    settings {
      # use Saskatchewan timezone b/c no DST
      [Setting.new(:timezone => "Saskatchewan", :languages => "eng", :outgoing_sms_adapter => "IntelliSms")]
    }
  end
end