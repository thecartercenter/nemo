require "spec_helper"

describe AnswersHelper do
  it "format_answer returns correct float value" do
    f = create(:form, question_types: %w(decimal))
    a = create(:answer, value: "123.28397928347392", questioning: f.questionings.first)
    expect(helper.format_answer(a, :table_cell)).to eq("123.28")
  end

  it "format_answer returns correct datetime value" do
    f = create(:form, question_types: %w(datetime))
    a = create(:answer, datetime_value: "2012-01-01 12:34", questioning: f.questionings.first)
    expect(helper.format_answer(a, :table_cell)).to eq("Jan 01 2012 12:34")
  end

  it "format_answer returns blank for nil datetime value" do
    f = create(:form, question_types: %w(datetime))
    a = create(:answer, datetime_value: nil, questioning: f.questionings.first)
    expect(helper.format_answer(a, :table_cell)).to eq("")
  end
end
