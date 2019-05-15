# frozen_string_literal: true

require "rails_helper"

describe "smart sort" do
  it "should smart-compare strings" do
    array = []
    expect(array.send(:smart_compare, "foo", "foo")).to eq(0)
    expect(array.send(:smart_compare, "foo", "FOO")).to eq(0)
    expect(array.send(:smart_compare, "10", "11")).to eq(-1)
    expect(array.send(:smart_compare, "10", "5")).to eq(1)
    expect(array.send(:smart_compare, "1 a", "1 b")).to eq(-1)
  end

  it "should smart-sort arrays" do
    list_unsorted = [
      {name: "foo"},
      {name: "bar"},
      {name: "10 baz"},
      {name: "5 baz"}
    ]
    list_sorted = [
      {name: "5 baz"},
      {name: "10 baz"},
      {name: "bar"},
      {name: "foo"}
    ]
    expect(list_unsorted.smart_sort_by_key).to eq(list_sorted)
  end
end
