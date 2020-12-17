# frozen_string_literal: true

require File.expand_path("../../spec/support/contexts/option_node_support", __dir__)

namespace :db do
  desc "Create fake data for manual testing purposes."
  task :create_fake_data, [:mission_name] => [:environment] do |_t, args|
    mission_name = args[:mission_name] || "Fake Mission #{rand(10_000)}"

    mission = Mission.create(name: mission_name)

    puts "Creating forms"
    sample_form = create(:form, :live, mission: mission, question_types: [
      "text",
      "long_text",
      "integer",
      "counter",
      "decimal",
      "location",
      %w[
        integer
        long_text
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

    FactoryBot.create(:form,
      name: "SMS Form",
      smsable: true,
      mission: mission,
      question_types: QuestionType.with_property(:smsable).map(&:name))

    puts "Creating users"
    # Create users and groups
    25.times do
      FactoryBot.create(:user, mission: mission, role_name: User::ROLES.sample)
    end

    FactoryBot.create_list(:user_group, 5, mission: mission)

    50.times do
      uga = UserGroupAssignment.new(user_group: UserGroup.all.sample, user: User.all.sample)
      uga.save if uga.valid?
    end

    # Define media paths
    image_path = Rails.root.join("spec/fixtures/media/images/the_swing.png")
    audio_path = Rails.root.join("spec/fixtures/media/audio/powerup.mp3")
    video_path = Rails.root.join("spec/fixtures/media/video/jupiter.mp4")

    print "Creating responses"

    mission.users.find_each do |user|
      3.times do
        print "."
        answer_values = [
          Faker::Pokemon.name, # text
          Faker::Hipster.paragraphs(number: 3).join("\n\n"), # long_text
          rand(1000..5000), # integer
          rand(1..100), # counter
          Faker::Number.decimal(l_digits: rand(1..3), r_digits: rand(1..5)), # decimal
          "#{Faker::Address.latitude} #{Faker::Address.longitude}", # location
          [rand(1..100), Faker::Hacker.say_something_smart], # integer/long text
          "Cat", # select_one
          %w[Plant Oak], # multilevel_select_one
          %w[Cat Dog], # select_multiple
          Faker::Time.backward(days: 365), # datetime
          Faker::Date.birthday, # date
          Faker::Time.between(from: 1.year.ago, to: Time.zone.today, format: :evening), # time
          FactoryBot.build(:media_image, file: File.open(image_path)), # image
          FactoryBot.build(:media_image, item: File.open(image_path)), # annotated image
          FactoryBot.build(:media_image, item: File.open(image_path)), # signature
          FactoryBot.build(:media_image, item: File.open(image_path)), # sketch
          FactoryBot.build(:media_audio, item: File.open(audio_path)), # audio
          FactoryBot.build(:media_video, item: File.open(video_path)) # video
        ]

        FactoryBot.create(:response,
          form: sample_form,
          user: user,
          mission: mission,
          answer_values: answer_values,
          created_at: Faker::Time.backward(days: 365))
      end
    end
    print "\n"

    puts "Created #{mission_name}"
  end
end
