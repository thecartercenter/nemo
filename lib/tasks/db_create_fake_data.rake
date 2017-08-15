require File.expand_path("../../../spec/support/option_node_support", __FILE__)

namespace :db do
  desc "Create fake data for manual testing purposes."
  task :create_fake_data, [:mission_name] => [:environment] do |t, args|
    mission_name = args[:mission_name] || "Fake Mission #{rand(10000)}"

    mission = Mission.create(name: mission_name)

    FactoryGirl.create(:form, mission: mission, question_types: [
      "text",
      "long_text",
      "integer",
      "counter",
      "decimal",
      "location",
      [
        "integer",
        "long_text"
      ],
      "select_one",
      "multilevel_select_one",
      "select_multiple",
      "datetime",
      "date",
      "time",
      "image",
      "annotated_image",
      "signature",
      "sketch",
      "audio",
      "video"
    ])
    FactoryGirl.create(:form,
      name: "SMS Form",
      smsable: true,
      mission: mission,
      question_types: QuestionType.with_property(:smsable).map(&:name)
    )

    # Create users and groups
    FactoryGirl.create_list(:user, 25)
    FactoryGirl.create_list(:user_group, 5, mission: mission)
    50.times do
      uga = UserGroupAssignment.new(user_group: UserGroup.all.sample, user: User.all.sample);
      uga.save if uga.valid?
    end

    puts "Created #{mission_name}"
  end
end
