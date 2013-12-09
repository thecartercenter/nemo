def get_mission
  Mission.find_by_name("MissionWithSettings") || FactoryGirl.create(:mission)
end

FactoryGirl.define do
  factory :mission do

    name "MissionWithSettings"
    setting {
      # use Saskatchewan timezone b/c no DST
      Setting.new(
        :timezone => "Saskatchewan",
        :preferred_locales_str => "en",
        :outgoing_sms_adapter => "IntelliSms",
        :intellisms_username => "user",
        :intellisms_password => "pass",
        :isms_hostname => "example.com:8080",
        :isms_username => "user",
        :isms_password => "pass"
      )
    }
  end
end
