require 'spec_helper'

describe ResponseCSV do
  context "with no data" do
    it "should generate empty string" do
      expect(ResponseCSV.new([]).to_s).to eq ""
    end
  end

  context "with some data without repeat groups" do
    let(:form1) do
      create(:form, question_types: ["text", "geo_multilevel_select_one", "long_text",
        "integer", "decimal", "location", "select_one", ["select_one", "select_one"],
        "select_multiple", "datetime", "date", "time"])
    end
    let(:form2) do
      create(:form, question_types: %w(text long_text geo_select_one)).tap do |f|
        # Share the mutli_level geo question with form1
        f.add_questions_to_top_level(form1.questions[1])
      end
    end

    before do
      FactoryGirl.reload # We rely on sequence numbers in expectation file

      # Use a weird timezone so we know times are handled properly.
      @old_tz = Time.zone
      Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

      # Need to freeze the time so the times in the expectation file match.
      # The times shown in the resulting CSV should be in the current zone, not UTC.
      # So 6:30am instead of 12:30pm.
      Timecop.freeze(Time.parse("2015-11-20 12:30 UTC")) do
        create(:response, id: 10, form: form1, answer_values: ["foo✓", %w(Canada Calgary),
          %Q{<p>foo</p><p>"bar"<br/>baz</p>}, 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15 UTC", "2014-11-09", "23:15"])

        # Response in the past to check sorting
        Timecop.freeze(-10.minutes) do
          create(:response,  id: 11, form: form1, answer_values: ["alpha", %w(Ghana Tamale), "bravo", 80, 1.23,
            nil, nil, ["Dog", nil], %w(Cat), "2015-01-12 09:15 UTC", "2014-02-03", "3:43"])
        end

        # Response with multilevel geo partial answer with node (Canada) with no coordinates
        create(:response,  id: 12, form: form1, answer_values: ["foo", %w(Canada), "bar", 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15 UTC", "2014-11-09", "23:15"])

        # Response with multilevel geo partial answer with node (Ghana) with coordinates
        create(:response,  id: 13, form: form1, answer_values: ["foo", %w(Ghana), "bar", 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15 UTC", "2014-11-09", "23:15"])

        # Response from second form
        create(:response,  id: 14, form: form2, answer_values: ["foo", "bar", "Funton", %w(Ghana Accra)])
      end
    end

    after do
      Time.zone = @old_tz
    end

    it "should generate correct CSV" do
      responses = Response.unscoped.with_associations.order(:created_at)
      expected = File.read(File.expand_path('../../expectations/response_csv/responses.csv', __FILE__))
      expect(ResponseCSV.new(responses).to_s).to eq expected
    end
  end

  context "with repeat groups" do
    let(:repeat_form) do
      create(:form, question_types: ["integer", [:repeating, "text", "integer"], "integer", [:repeating, "text", "integer"]]).tap do |f|
        f.children[1].update_attribute(:repeatable, true)
      end
    end

    let(:response_a) do
      create(:response, id: 101, form: repeat_form, answer_values: [
        1,
        [:repeating,
          ["Apple", 1],
          ["Banana", 2]
        ],
        2,
        [:repeating,
          ["Asparagus", 3]
        ]
      ])
    end

    let(:response_b) do
      create(:response, id: 102, form: repeat_form, answer_values: [
        3,
        [:repeating,
          ["Xigua", 10],
          ["Yuzu", 9],
          ["Ugli", 8]
        ],
        4,
        [:repeating,
          ["Zucchini", 7],
          ["Yam", 6]
        ]
      ])
    end

    # Use a specific timezone
    @old_tz = Time.zone
    Time.zone = ActiveSupport::TimeZone["Saskatchewan"]

    it "should generate a row per repeat group answer, plus one row per responseß" do
      FactoryGirl.reload
      Timecop.freeze(Time.parse("2015-11-20 12:30 UTC")) do
        response_a
        response_b
      end

      responses = Response.order(:id)
      expected = File.read(File.expand_path('../../expectations/response_csv/repeat_groups.csv', __FILE__))
      actual = ResponseCSV.new(responses)
      expect(actual.to_s).to eq expected
    end

    after do
      Time.zone = @old_tz
    end
  end

end
