# frozen_string_literal: true

require "rails_helper"

describe Results::Csv::Generator, :reset_factory_sequences do
  let(:relation) { Response.all }
  let(:responses) { [] }
  subject(:output) { Results::Csv::Generator.new(relation).to_s }

  around do |example|
    # Use a weird timezone so we know times are handled properly.
    in_timezone("Saskatchewan") { example.run }
  end

  context "with no data" do
    it "produces correct csv" do
      is_expected.to eq "ResponseID,Shortcode,Form,Submitter,DateSubmitted,"\
        "GroupNum1,ItemNum1,GroupName,GroupLevel\r\n"
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
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
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
        Timecop.freeze(10.minutes) do
          create_response(
            form: form1,
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
      is_expected.to eq prepare_response_csv_expectation("basic.csv")
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
             "select_multiple"                         # 4
           ]}},
           "integer",                                  # 5
           {repeating: {name: "Vegetable", items: [
             "text",                                   # 6
             "geo_multilevel_select_one",              # 7
             "integer"                                 # 8
           ]}}])
    end

    before do
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        create_response(form: repeat_form, answer_values: [
          1,
          {repeating: [
            ["Apple", 1, %w[Cat Dog]],
            ["Banana", 2, %w[Cat]]
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
              ["Yuzu", 9, %w[Cat Dog]],
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
      is_expected.to eq prepare_response_csv_expectation("with_repeat_groups.csv")
    end
  end

  context "with multiline data, html, quoted strings, and commas" do
    let(:form1) { create(:form, question_types: ["text"]) }

    before do
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        Timecop.freeze(1.minute) do
          create_response(form: form1, answer_values: [%(<p>foo</p><p>"bar"<br/>baz, stuff</p>)])
        end
        Timecop.freeze(2.minutes) do
          create_response(form: form1, answer_values: [%(bar,baz)])
        end
        Timecop.freeze(3.minutes) do
          create_response(form: form1, answer_values: [%(\r\nwin\r\n\r\nfoo\r\n)]) # Win line endings
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
      is_expected.to eq prepare_response_csv_expectation("multiline.csv")
    end
  end

  context "with multimedia questions" do
    let(:form1) { create(:form, question_types: %w[text image]) }

    before do
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        image_obj = Media::Image.create!(item: media_fixture("images/the_swing.jpg"))
        create_response(form: form1, answer_values: ["foo", image_obj])
      end
    end

    # We don't currrently support attachments in CSV output.
    it "ignores attached files" do
      is_expected.to eq prepare_response_csv_expectation("media.csv")
    end
  end

  context "with deleted response and answer" do
    let(:form1) { create(:form, question_types: %w[text text]) }
    let(:form2) { create(:form, question_types: %w[text]) }

    before do
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
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
      is_expected.to eq prepare_response_csv_expectation("with_deleted.csv")
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
      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        create_response(form: form1, mission: missions[0], answer_values: ["foo"])
        create_response(form: form2, mission: missions[1], answer_values: ["bar"])
      end
    end

    it "ignores form2 since it's from other mission" do
      is_expected.to eq prepare_response_csv_expectation("scoped_relation.csv")
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

      I18n.locale = :fr
      group.update!(group_name_fr: "Groupe")
      option.update!(name_fr: "L'option")

      Timecop.freeze(Time.zone.parse("2015-11-20 12:30 UTC")) do
        create_response(form: form, answer_values: [[option.name]])
      end
    end

    it "uses french names when appropriate" do
      is_expected.to eq prepare_response_csv_expectation("multilingual.csv")
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
