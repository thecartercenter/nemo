# frozen_string_literal: true

require "rails_helper"

describe "searches helper" do
  include SearchesHelper

  it "should smart-compare strings" do
    expect(simple_smart_compare("foo", "foo")).to eq(0)
    expect(simple_smart_compare("foo", "FOO")).to eq(0)
    expect(simple_smart_compare("10", "11")).to eq(-1)
    expect(simple_smart_compare("10", "5")).to eq(1)
    expect(simple_smart_compare("1 a", "1 b")).to eq(-1)
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
    expect(simple_smart_sort(list_unsorted)).to eq(list_sorted)
  end
end
