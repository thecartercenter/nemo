require 'spec_helper'

describe ResponseCSV do
  context "with no data" do
    it "should generate empy string" do
      expect(ResponseCSV.new([]).to_s).to eq ""
    end
  end

  context "with some data" do
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

      # Need to freeze the time so the times in the expectation file match.
      Timecop.freeze("2015-11-20 12:30") do
        create(:response, form: form1, answer_values: ["foo✓", %w(Canada Calgary),
          %Q{<p>foo</p><p>"bar"<br/>baz</p>}, 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15", "2014-11-09", "23:15"])

        # Response in the past to check sorting
        Timecop.freeze(-10.minutes) do
          create(:response, form: form1, answer_values: ["alpha", %w(Ghana Tamale), "bravo", 80, 1.23,
            nil, nil, ["Dog", nil], %w(Cat), "2015-01-12 09:15", "2014-02-03", "3:43"])
        end

        # Response with multilevel geo partial answer with node (Canada) with no coordinates
        create(:response, form: form1, answer_values: ["foo", %w(Canada), "bar", 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15", "2014-11-09", "23:15"])

        # Response with multilevel geo partial answer with node (Ghana) with coordinates
        create(:response, form: form1, answer_values: ["foo", %w(Ghana), "bar", 100, -123.50,
          "15.937378 44.36453", "Cat", %w(Dog Cat), %w(Dog Cat),
          "2015-10-12 18:15", "2014-11-09", "23:15"])

        # Response from second form
        create(:response, form: form2, answer_values: ["foo", "bar", "Funton", %w(Ghana Accra)])
      end
    end

    it "should generate correct CSV" do
      responses = Response.unscoped.with_associations.order(:created_at)
      expected = File.read(File.expand_path('../../expectations/responses.csv', __FILE__))
      expect(ResponseCSV.new(responses).to_s).to eq expected
    end
  end
end