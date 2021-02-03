# frozen_string_literal: true

require "rails_helper"

describe Results::CSV::Generator, :reset_factory_sequences do
  let(:relation) { Response.all }
  let(:responses) { [] }
  let(:options) { {} }
  let(:generator) { Results::CSV::Generator.new(relation, options: options) }
  let(:submission_time) { Time.zone.parse("2015-11-20 12:30 UTC") }
  subject(:output) { generator.export.read }

  around do |example|
    # Use a weird timezone so we know times are handled properly.
    in_timezone("Saskatchewan") { example.run }
  end

  context "with no data" do
    it "produces correct csv" do
      is_expected.to match_user_facing_csv("ResponseID,Shortcode,Form,Submitter,DateSubmitted,"\
        "Reviewed,GroupName,GroupLevel\r\n")
    end
  end

  context "with lots of question types and a non-repeat group" do
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
      Timecop.freeze(submission_time) do
        create_response(
          form: form1,
          answer_values: ["foo✓", %w[Canada Calgary],
                          "alpha", 100, -123.50,
                          "15.937378 44.36453", "Cat", %w[Dog Cat], %w[Dog Cat],
                          "2015-10-12 18:15:12 UTC", "2014-11-09", "23:15"]
        )

        # We put this one out of order to ensure sorting works.
        Timecop.freeze(-10.minutes) do
          responses.insert(0, create(:response,
            form: form1,
            answer_values: ["alpha", %w[Ghana Tamale], "bravo", 80, 1.23, nil, nil,
                            ["Dog", nil], %w[Cat], "2015-01-12 09:15:12 UTC", "2014-02-03", "3:43"]))
        end

        # Response with multilevel geo partial answer with node (Canada) with no coordinates
        # Also testing reviewed column true here.
        Timecop.freeze(10.minutes) do
          create_response(
            form: form1, reviewed: true,
            answer_values: ["foo", %w[Canada], "bar", 100, -123.50,
                            "15.937378 44.36453", "Cat", %w[Dog Cat], %w[Dog Cat],
                            "2015-10-12 18:15 UTC", "2014-11-09", "23:15:19"]
          )
        end

        Timecop.freeze(15.minutes) do
          # Response with multilevel geo partial answer with node (Ghana) with coordinates
          # and geo answer altitude & accuracy
          create_response(
            form: form1,
            answer_values: ["foo", %w[Ghana], "bar", 100, -123.50,
                            "15.937378 44.36453 123.45 20.4", "Cat", %w[Dog Cat], %w[Dog Cat],
                            "2015-10-12 18:15 UTC", "2014-11-09", "23:15:19"]
          )
        end

        Timecop.freeze(20.minutes) do
          # Response from second form
          create_response(form: form2,
                          answer_values: ["foo", "bar", "Funton", %w[Ghana Accra]])
        end
      end
    end

    it "produces correct csv" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("basic.csv"))
    end
  end

  context "with repeat groups" do
    let(:repeat_form) do
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

    before do
      Timecop.freeze(submission_time) do
        create_response(form: repeat_form, answer_values: [
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

        Timecop.freeze(10.minutes) do
          create_response(form: repeat_form, answer_values: [
            3,
            {repeating: [
              ["Xigua", 10, %w[Dog]],
              ["Yuzu", 9, %w[Cat Dog], {repeating: [[1.52]]}],
              ["Ugli", 8, %w[Cat]]
            ]},
            4,
            {repeating: [
              ["Zucchini", %w[Canada Calgary], 7],
              ["Yam", %w[Canada Ottawa], 6]
            ]}
          ])
        end
      end
    end

    it "produces correct csv" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("with_repeat_groups.csv"))
    end
  end

  context "with multiline data, html, quoted strings, and commas" do
    let(:form1) { create(:form, question_types: ["text"]) }

    before do
      Timecop.freeze(submission_time) do
        Timecop.freeze(1.minute) do
          create_response(
            form: form1,
            answer_values: [%(<p>foo</p><p>"bar"<br/>baz, stuff</p>)]
          )
        end
        Timecop.freeze(2.minutes) do
          create_response(form: form1, answer_values: [%(bar,baz)])
        end
        Timecop.freeze(3.minutes) do
          create_response(
            form: form1,
            answer_values: [%(\r\nwin\r\n\r\nfoo\r\n)]
          ) # Win line endings
        end
        Timecop.freeze(4.minutes) do
          create_response(form: form1, answer_values: [%(\nunix\n\nfoo\n)]) # Unix line endings
        end
        Timecop.freeze(5.minutes) do
          create_response(form: form1, answer_values: [%(\rmac\r\rfoo\r)]) # Mac line endings
        end
      end
    end

    it "produces correct csv" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("multiline.csv"))
    end
  end

  context "with multimedia questions" do
    let(:form1) { create(:form, question_types: %w[text image]) }

    before do
      Timecop.freeze(submission_time) do
        image_obj = create(:media_image)
        create_response(form: form1, answer_values: ["foo", image_obj])
      end
    end

    # We don't currrently support attachments in CSV output.
    it "ignores attached files" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("media.csv"))
    end
  end

  context "with deleted response and answer" do
    let(:form1) { create(:form, question_types: %w[text text]) }
    let(:form2) { create(:form, question_types: %w[text]) }

    before do
      Timecop.freeze(submission_time) do
        Timecop.freeze(1.minute) do
          create_response(form: form1, answer_values: %w[foo bar])
        end
        Timecop.freeze(2.minutes) do
          # Destroy one of the answers for this response, but not the whole thing.
          create_response(form: form1, answer_values: %w[baz qux])
          responses.last.root_node.c[1].destroy

          # form2 has no responses in our set so its headers shouldn't be included either.
          create_response(form: form2, answer_values: ["xuq"])
          responses.last.destroy
        end
      end
    end

    it "ignores deleted responses" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("with_deleted.csv"))
    end
  end

  context "with scoped relation" do
    let(:missions) { create_list(:mission, 2) }
    let!(:form1) { create(:form, mission: missions[0], question_types: %w[text]) }
    let!(:form2) { create(:form, mission: missions[1], question_types: %w[text]) }
    let(:relation) do
      # Simulate some conditions like we'd get from a search.
      Response.for_mission(get_mission).joins(:form)
        .where("(((responses.reviewed = 'n')) AND ((forms.name ILIKE '%Sample%')))")
    end

    before do
      Timecop.freeze(submission_time) do
        create_response(form: form1, mission: missions[0], answer_values: ["foo"])
        create_response(form: form2, mission: missions[1], answer_values: ["bar"])
      end
    end

    it "ignores form2 since it's from other mission" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("scoped_relation.csv"))
    end
  end

  context "with multilingual group and option names" do
    let(:form) { create(:form, question_types: [{repeating: {items: ["select_one"]}}]) }
    let(:group) { form.c[0] }
    let(:option) { form.c[0].c[0].option_set.c[0].option }

    before do
      # Avoid missing translation errors for headers. We're not testing those here as
      # those are picked up with standard I18n.translate. In production this isn't an issue
      # because fallbacks are enabled.
      I18n.backend.store_translations(:fr, response: {csv_headers: I18n.t("response.csv_headers")})

      configatron.preferred_locales = %i[en fr]
      I18n.locale = :fr
      group.update!(group_name_fr: "Groupe")
      option.update!(name_fr: "L'option")

      Timecop.freeze(submission_time) do
        create_response(form: form, answer_values: [{repeating: [[option.name_en]]}])
      end
    end

    it "uses french names when appropriate" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("multilingual.csv"))
    end
  end

  context "with numeric values for select_one and select_multiple questions" do
    let(:form) { create(:form, question_types: %w[select_one select_multiple]) }

    before do
      form.c[0].option_set.options[0].update!(value: 2)
      form.c[0].option_set.options[1].update!(value: 3)
      form.c[1].option_set.options[0].update!(value: 5)
      form.c[1].option_set.options[1].update!(value: 8)
      Timecop.freeze(submission_time) do
        create_response(form: form, answer_values: ["Cat", %w[Cat Dog]])
      end
    end

    it "exports numeric values" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("option_values.csv"))
    end
  end

  context "with long_text_behavior" do
    let(:options) { {long_text_behavior: "truncate"} }
    let(:form) { create(:form, question_types: %w[text long_text]) }

    before do
      stub_const(Results::CSV::AnswerProcessor, "MAX_CHARACTERS", 6)
      Timecop.freeze(submission_time) do
        create_response(form: form, answer_values: ["regular text preserved", "long text truncated"])
      end
    end

    it "exports truncated values" do
      is_expected.to match_user_facing_csv(prepare_response_csv_expectation("truncated_values.csv"))
    end
  end

  def create_response(params)
    responses << create(:response, params)
  end

  def prepare_response_csv_expectation(filename)
    prepare_fixture("response_csv/#{filename}",
      id: responses.map(&:id), shortcode: responses.map(&:shortcode))
  end
end
