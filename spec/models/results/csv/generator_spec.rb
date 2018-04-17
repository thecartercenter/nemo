# frozen_string_literal: true

require "spec_helper"

describe Results::Csv::Generator, :reset_factory_sequences do
  let(:responses) { Response.with_associations.order(:created_at) }
  let(:generated_csv) { Results::Csv::Generator2.new(responses).to_s }
  let(:ordered_responses) { Response.with_associations.order(:created_at) }

  around do |example|
    # Use a weird timezone so we know times are handled properly.
    @old_tz = Time.zone
    Time.zone = ActiveSupport::TimeZone["Saskatchewan"]
    example.run
    Time.zone = @old_tz
  end

  context "with no data" do
    it "should generate empty string" do
      expect(generated_csv).to eq ""
    end
  end

  context "with some data without repeat groups" do
    let(:form1) do
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
                                     "time"])                      # 13
    end
    let(:form2) do
      create(:form, question_types: %w[text long_text geo_select_one]).tap do |f|
        # Share the mutli_level geo question with form1
        f.add_questions_to_top_level(form1.questions[1])
      end
    end

    before do
      # Need to freeze the time so the times in the expectation file match.
      # The times shown in the resulting CSV should be in the current zone, not UTC.
      # So e.g. 6:30am instead of 12:30pm.
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        create(:response,
          id: 10,
          form: form1,
          answer_values: ["foo✓", %w[Canada Calgary],
                          "alpha", 100, -123.50,
                          "15.937378 44.36453", "Cat", %w[Dog Cat], %w[Dog Cat],
                          "2015-10-12 18:15:12 UTC", "2014-11-09", "23:15"])

        # We put this one out of order to ensure sorting works.
        Timecop.freeze(-10.minutes) do
          create(:response,
            id: 11,
            form: form1,
            answer_values: ["alpha", %w[Ghana Tamale], "bravo", 80, 1.23, nil, nil,
                            ["Dog", nil], %w[Cat], "2015-01-12 09:15:12 UTC", "2014-02-03", "3:43"])
        end

        # Response with multilevel geo partial answer with node (Canada) with no coordinates
        Timecop.freeze(10.minutes) do
          create(:response,
            id: 12,
            form: form1,
            answer_values: ["foo", %w[Canada], "bar", 100, -123.50,
                            "15.937378 44.36453", "Cat", %w[Dog Cat], %w[Dog Cat],
                            "2015-10-12 18:15 UTC", "2014-11-09", "23:15:19"])
        end

        Timecop.freeze(15.minutes) do
          # Response with multilevel geo partial answer with node (Ghana) with coordinates
          # and geo answer altitude & accuracy
          create(:response,
            id: 13,
            form: form1,
            answer_values: ["foo", %w[Ghana], "bar", 100, -123.50,
                            "15.937378 44.36453 123.45 20.4", "Cat", %w[Dog Cat], %w[Dog Cat],
                            "2015-10-12 18:15 UTC", "2014-11-09", "23:15:19"])
        end

        Timecop.freeze(20.minutes) do
          # Response from second form
          create(:response,
            id: 14,
            form: form2,
            answer_values: ["foo", "bar", "Funton", %w[Ghana Accra]])
        end
      end
    end

    it "should generate correct CSV" do
      expect(generated_csv).to eq prepare_response_csv_expectation("basic.csv")
    end
  end

  context "with repeat groups" do
    let(:repeat_form) do
      create(:form,
        question_types:
          ["integer",
           {repeating: {items: %w[text integer select_multiple], name: "Fruit"}},
           "integer",
           {repeating: {items: %w[text geo_multilevel_select_one integer], name: "Vegetable"}}]).tap do |f|
        f.sorted_children[1].update!(repeatable: true)
      end
    end
    let(:response_a) do
      create(:response, form: repeat_form, answer_values: [
        1,
        [:repeating,
         ["Apple", 1, %w[Cat Dog]],
         ["Banana", 2, %w[Cat]]],
        2,
        [:repeating,
         ["Asparagus", %w[Ghana Accra], 3]]
      ])
    end
    let(:response_b) do
      create(:response, form: repeat_form, answer_values: [
        3,
        [:repeating,
         ["Xigua", 10, %w[Dog]],
         ["Yuzu", 9, %w[Cat Dog]],
         ["Ugli", 8, %w[Cat]]],
        4,
        [:repeating,
         ["Zucchini", %w[Canada Calgary], 7],
         ["Yam", %w[Canada Ottawa], 6]]
      ])
    end

    it "should generate a row per repeat group answer, plus one row per response" do
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        response_a
        Timecop.freeze(10.minutes) { response_b }
      end
      File.open(Rails.root.join("tmp", "out.csv"), "w") { |f| f.write(generated_csv) }
      expect(generated_csv).to eq prepare_response_csv_expectation("with_repeat_groups.csv")
    end
  end

  def prepare_response_csv_expectation(filename)
    prepare_expectation("response_csv/#{filename}",
      id: responses.map(&:id), shortcode: responses.map(&:shortcode))
  end
end
