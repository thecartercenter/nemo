require 'spec_helper'

describe ResponseCSV do
  context "with no data" do
    it "should generate trivial string" do
      expect(ResponseCSV.new([]).to_s).to eq "Form,Submitter,DateSubmitted,Response\r\n"
    end
  end

  context "with some data" do
    let(:form1) do
      create(:form, question_types: ["text", "long_text", "integer", "decimal", "location", "select_one",
        ["select_one", "select_one"],
        "geo_multi_level_select_one", "select_multiple", "datetime", "date", "time"])
    end
    let(:form2) do
      create(:form, question_types: %w(text long_text geo_multi_level_select_one))
    end

    before do
      create(:response, form: form1, answer_values: ["foo✓", "bar\nbaz", 100, -123.50, "15.937378 44.36453", "Cat",
        %w(Dog Cat), %w(Canada Calgary), %w(Dog Cat), "2015-10-12 18:15", "2014-11-09", "23:15"])
      Timecop.freeze(-10.minutes) do
        create(:response, form: form1, answer_values: ["alpha", "bravo", 80, 1.23, nil, nil,
          ["Dog", nil], %w(Ghana Tamale), %w(Cat), "2015-01-12 09:15", "2014-02-03", "3:43"])
      end
    end

    it "should generate correct CSV" do
      expect(ResponseCSV.new(Response.all).to_s).to eq "foo"
    end
  end
end