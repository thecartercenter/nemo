# frozen_string_literal: true

require "spec_helper"

describe Results::Csv::HeaderMap do
  let(:header_map) { described_class.new }

  it "should remember existing and create new as needed" do
    expect(header_map.index_for("foo")).to eq 0
    expect(header_map.index_for("foo")).to eq 0
    expect(header_map.index_for("bar")).to eq 1
    expect(header_map.index_for("bar")).to eq 1
    expect(header_map.index_for("baz")).to eq 2
  end
end
