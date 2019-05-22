# frozen_string_literal: true

require "rails_helper"

describe "sorting" do
  # Naive sort based on ASCII comparison (because that's all the database supports).
  # For a natural sort implementation see https://github.com/thecartercenter/nemo/pull/605.
  it "should sort arrays by key" do
    list_unsorted = [
      {name: "c"},
      {name: "a"},
      {name: "ä"},
      {name: "D"},
      {name: "b"}
    ]
    list_sorted = [
      {name: "D"},
      {name: "a"},
      {name: "b"},
      {name: "c"},
      {name: "ä"}
    ]
    expect(list_unsorted.sort_by_key).to eq(list_sorted)
  end
end
