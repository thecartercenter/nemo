# frozen_string_literal: true

require "rails_helper"

describe Results::Csv::GroupPath do
  let(:path) { described_class.new(max_depth: depth) }

  context "with nested groups" do
    let(:depth) { 2 }

    it "should process properly" do
      expect(path.changes).to be_nil
      expect(path.changed?).to be false

      # Start with a nested answer.
      path.process_row(
        "response_id" => "1",
        "group1_rank" => "2",
        "group1_inst_num" => "1",
        "group2_rank" => "4",
        "group2_inst_num" => "2"
      )

      # Response and both group levels have changed, hence the 3.
      expect(path.changes).to eq [0, 3]
      expect(path.changed?).to be true

      # Next answer is root-level.
      path.process_row(
        "response_id" => "1",
        "group1_rank" => nil,
        "group1_inst_num" => nil,
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [-2, 0]
      expect(path.changed?).to be true

      # Down to first level group on new response.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "1",
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [-1, 2]
      expect(path.changed?).to be true

      # No change.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "1",
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [0, 0]
      expect(path.changed?).to be false

      # Into next item.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "2",
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [-1, 1]

      # Into second level.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "2",
        "group2_rank" => "7",
        "group2_inst_num" => "1"
      )
      expect(path.changes).to eq [0, 1]

      # Into first level of later group.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "9",
        "group1_inst_num" => "1",
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [-2, 1]

      # Back to root.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => nil,
        "group1_inst_num" => nil,
        "group2_rank" => nil,
        "group2_inst_num" => nil
      )
      expect(path.changes).to eq [-1, 0]
    end
  end

  context "with single depth group" do
    let(:depth) { 1 }

    it "should process properly" do
      expect(path.changes).to be_nil

      # Start with a nested answer.
      path.process_row(
        "response_id" => "1",
        "group1_rank" => "2",
        "group1_inst_num" => "1"
      )

      # Response and both group levels have changed, hence the 2.
      expect(path.changes).to eq [0, 2]

      # Next answer is root-level.
      path.process_row(
        "response_id" => "1",
        "group1_rank" => nil,
        "group1_inst_num" => nil
      )
      expect(path.changes).to eq [-1, 0]

      # Down to first level group on new response.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "1"
      )
      expect(path.changes).to eq [-1, 2]

      # No change.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "1"
      )
      expect(path.changes).to eq [0, 0]

      # Into next item.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "3",
        "group1_inst_num" => "2"
      )
      expect(path.changes).to eq [-1, 1]

      # Into later group.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => "9",
        "group1_inst_num" => "1"
      )
      expect(path.changes).to eq [-1, 1]

      # Back to root.
      path.process_row(
        "response_id" => "2",
        "group1_rank" => nil,
        "group1_inst_num" => nil
      )
      expect(path.changes).to eq [-1, 0]
    end
  end
end
