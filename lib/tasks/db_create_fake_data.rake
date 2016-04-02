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

    puts "Created #{mission_name}"
  end
end
