# frozen_string_literal: true

require "rails_helper"

describe Results::ResponseJsonGenerator, :reset_factory_sequences do
  let(:submission_time) { Time.zone.parse("2020-04-20 12:30 UTC") }
  subject(:object) { described_class.new(response).as_json }

  around do |example|
    # Use a weird timezone so we know times are handled properly.
    in_timezone("Saskatchewan") do
      # Need to freeze the time so the times in the expectation file match.
      # The times shown in the resulting JSON should be in the current zone, not UTC.
      # So e.g. 6:30am instead of 12:30pm.
      Timecop.freeze(submission_time) { example.run }
    end
  end

  context "response with various question types" do
    let(:form) do
      create(:form, question_types: ["text",                       # 1
                                     "geo_multilevel_select_one",  # 2
                                     "long_text",                  # 3
                                     "integer",                    # 4
                                     "decimal",                    # 5
                                     "location",                   # 6
                                     "select_one",                 # 7
                                     %w[select_one select_one],    # 8, 9
                                     "select_multiple",            # 10
                                     "datetime",                   # 11
                                     "date",                       # 12
                                     "time",                       # 13
                                     "image"])                     # 14
    end

    let(:image) do
      create(:media_image)
    end

    let(:response) do
      create(:response, form: form,
                        answer_values: ["foo✓", %w[Canada Calgary],
                                        "alpha", 100, -123.50,
                                        "15.937378 44.36453", "Cat", %w[Dog Cat], %w[Dog Cat],
                                        "2015-10-12 18:15:12 UTC", "2014-11-09", "23:15", image])
    end

    it "produces correct json" do
      path = Rails.application.routes.url_helpers.rails_blob_url(image.item, disposition: "attachment",
                                                                             only_path: true)
      "#{Results::ResponseJsonGenerator::BASE_URL_PLACEHOLDER}#{path}"
      is_expected.to match_json(prepare_response_json_expectation("basic.json", path: [path]))
    end
  end

  context "response with repeat groups" do
    let(:form) do
      create(:form,
        question_types:
          ["integer",                                  # 1
           {repeating: {name: "Fruit", items: [
             "text",                                   # 2
             "integer",                                # 3
             "select_multiple",                        # 4
             {repeating: {name: "Slice", items: [
               "decimal"                               # 5
             ]}}
           ]}},
           "integer",                                  # 6
           {repeating: {name: "Vegetable", items: [
             "text",                                   # 7
             "geo_multilevel_select_one",              # 8
             "integer"                                 # 9
           ]}}])
    end
    let(:response) do
      create(:response, form: form, reviewed: true, answer_values: [
        1,
        {repeating: [
          ["Apple", 1, %w[Cat Dog], {repeating: [[1.65], [1.3]]}],
          ["Banana", 2, %w[Cat], {repeating: [[1.27], [1.77]]}]
        ]},
        2,
        {repeating: [
          ["Asparagus", %w[Ghana Accra], 3]
        ]}
      ])
    end

    it "produces correct json" do
      is_expected.to match_json(prepare_response_json_expectation("repeats.json"))
    end
  end

  context "response with missing values" do
    let(:form) do
      create(:form, question_types: ["text"])
    end
    let!(:response) do
      create(:response, form: form, reviewed: true, answer_values: ["foo"])
    end

    it "produces correct json with defaults" do
      create(:questioning, form: form, question: create(:question, qtype_name: "text"))
      create(:questioning, form: form, question:
        create(:question, qtype_name: "select_multiple", option_names: %w[one two]))
      is_expected.to match_json(prepare_response_json_expectation("legacy_new_qings.json"))
    end
  end

  context "legacy response - repeat group that no longer repeats" do
    let(:form) do
      create(:form,
        question_types:
          [{repeating: {name: "Fruit", items: [
            "text",                                   # 1
            "integer",                                # 2
            {repeating: {name: "Slice", items: [
              "decimal"                               # 3
            ]}}
          ]}}])
    end
    let!(:response) do
      create(:response, form: form, reviewed: true, answer_values: [
        # This is submitted as a repeat group, but will later NOT repeat.
        # The second entry is not expected to render anymore.
        {repeating: [
          ["Apple", 1, {repeating: [[1.65], [1.3]]}],
          ["Banana", 2, {repeating: [[1.27], [1.77]]}]
        ]}
      ])
    end

    it "produces correct json" do
      form.c[0].update!(repeatable: false)
      is_expected.to match_json(prepare_response_json_expectation("legacy_repeat_now_group.json"))
    end
  end

  context "legacy response - group that now repeats" do
    let(:form) do
      create(:form,
        question_types:
          [[
            "text",                                   # 1
            "integer",                                # 2
            {repeating: {name: "Slice", items: [
              "decimal"                               # 3
            ]}}
          ]])
    end
    let!(:response) do
      create(:response, form: form, reviewed: true, answer_values: [
        # This is submitted as a regular group, but will later repeat.
        ["Apple", 1, {repeating: [[1.65], [1.3]]}]
      ])
    end

    it "produces correct json" do
      form.c[0].update!(repeatable: true)
      is_expected.to match_json(prepare_response_json_expectation("legacy_group_now_repeat.json"))
    end
  end

  def prepare_response_json_expectation(filename, **substitutions)
    prepare_fixture("response_json/#{filename}",
      id: [response.id], shortcode: [response.shortcode], **substitutions)
  end
end
