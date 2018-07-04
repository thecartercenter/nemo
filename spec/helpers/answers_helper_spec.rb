# frozen_string_literal: true

require "rails_helper"

describe AnswersHelper do
  it "format_answer returns correct float value" do
    form = create(:form, question_types: %w[decimal])
    answer = build(:answer, value: "123.28397928347392", questioning: form.c[0])
    expect(helper.format_answer(answer, :table_cell)).to eq("123.28")
  end

  it "format_answer returns correct datetime value" do
    form = create(:form, question_types: %w[datetime])
    answer = build(:answer, datetime_value: "2012-01-01 12:34:56", questioning: form.c[0])
    expect(helper.format_answer(answer, :table_cell)).to eq("Jan 01 2012 12:34:56")
  end

  it "format_answer returns blank for nil datetime value" do
    form = create(:form, question_types: %w[datetime])
    answer = build(:answer, datetime_value: nil, questioning: form.c[0])
    expect(helper.format_answer(answer, :table_cell)).to eq("")
  end
end
