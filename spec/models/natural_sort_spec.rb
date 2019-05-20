# frozen_string_literal: true

require "rails_helper"

describe "natural sort" do
  it "should natural-compare strings" do
    expect("foo".to_sort_atoms <=> "FOO".to_sort_atoms).to eq(0)
    expect("foo".to_sort_atoms <=> "FOO".to_sort_atoms).to eq(0)
    expect("Aa".to_sort_atoms <=> "Ää".to_sort_atoms).to eq(0)
    expect("10".to_sort_atoms <=> "11".to_sort_atoms).to eq(-1)
    expect("10".to_sort_atoms <=> "5".to_sort_atoms).to eq(1)
    expect("a 10".to_sort_atoms <=> "a 5".to_sort_atoms).to eq(1)
    expect("1 a".to_sort_atoms <=> "1 b".to_sort_atoms).to eq(-1)
  end

  it "should natural-sort arrays" do
    list_unsorted = [
      {name: "foo"},
      {name: "bar"},
      {name: "baz 10"},
      {name: "baz 5"},
      {name: "10 baz"},
      {name: "5 baz"}
    ]
    list_sorted = [
      {name: "5 baz"},
      {name: "10 baz"},
      {name: "bar"},
      {name: "baz 5"},
      {name: "baz 10"},
      {name: "foo"}
    ]
    expect(list_unsorted.natural_sort_by_key).to eq(list_sorted)
  end
end
