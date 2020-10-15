# frozen_string_literal: true

require "rails_helper"

describe Results::CSV::GroupPath do
  let(:path) { described_class.new }

  # Random form item IDs to be used as the form item IDs related to nodes.
  10.times do |i|
    let(:"fi#{i}") { SecureRandom.uuid }
  end

  it "should work with nested groups" do
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be(false)

    # Start with a nested answer.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},"\
        "AnswerGroupSet:0:#{fi2},AnswerGroup:0:#{fi2},Answer:0:#{fi3}}"
    )

    # Response and both group levels have changed, hence the 3.
    expect(path.changes).to eq([0, 3])
    expect(path.changed?).to be(true)
    expect(path.parent_repeat_group_id).to eq(fi2)

    # Next answer is root-level.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup:0:#{fi0},Answer:1:#{fi4}}"
    )
    expect(path.changes).to eq([-2, 0])
    expect(path.changed?).to be(true)
    expect(path.parent_repeat_group_id).to be_nil

    # Next answer is in non-repeat group (no change).
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroup:2:#{fi5},Answer:0:#{fi6}}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be(false)
    expect(path.parent_repeat_group_id).to be_nil

    # Down to first level of repeat group on new response.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},Answer:0:#{fi7}}"
    )
    expect(path.changes).to eq([-1, 2])
    expect(path.changed?).to be(true)
    expect(path.parent_repeat_group_id).to eq(fi1)

    # No change in group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},Answer:1:#{fi8}}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be(false)
    expect(path.parent_repeat_group_id).to eq(fi1)

    # Into next item.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:1:#{fi1},Answer:0:#{fi7}}"
    )
    expect(path.changes).to eq([-1, 1])
    expect(path.parent_repeat_group_id).to eq(fi1)

    # Into second level nested group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:1:#{fi1},"\
        "AnswerGroupSet:1:#{fi2},AnswerGroup:0:#{fi2},Answer:0:#{fi3}}"
    )
    expect(path.changes).to eq([0, 1])
    expect(path.parent_repeat_group_id).to eq(fi2)

    # Into first level of later, non-repeat group (non-repeat groups don't count as path changes).
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroup:1:#{fi5},Answer:0:#{fi6}}"
    )
    expect(path.changes).to eq([-2, 0])
    expect(path.parent_repeat_group_id).to be_nil

    # Back to root.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},Answer:2:#{fi9}}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.parent_repeat_group_id).to be_nil
  end

  it "should work with single depth group" do
    expect(path.changes).to eq([0, 0])

    # Start with a nested answer.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},Answer:0:#{fi2}}"
    )

    # Response and both group levels have changed, hence the 2.
    expect(path.changes).to eq([0, 2])
    expect(path.parent_repeat_group_id).to eq(fi1)

    # Next answer is root-level.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup:0:#{fi0},Answer:1:#{fi3}}"
    )
    expect(path.changes).to eq([-1, 0])
    expect(path.parent_repeat_group_id).to be_nil

    # Down to first level group on new response.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},Answer:0:#{fi2}}"
    )
    expect(path.changes).to eq([-1, 2])
    expect(path.parent_repeat_group_id).to eq(fi1)

    # No change.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:0:#{fi1},Answer:1:#{fi3}}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.parent_repeat_group_id).to eq(fi1)

    # Into next item.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:0:#{fi1},AnswerGroup:1:#{fi1},Answer:0:#{fi2}}"
    )
    expect(path.changes).to eq([-1, 1])
    expect(path.parent_repeat_group_id).to eq(fi1)

    # Into later group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},AnswerGroupSet:1:#{fi4},AnswerGroup:0:#{fi4},Answer:0:#{fi5}}"
    )
    expect(path.changes).to eq([-1, 1])
    expect(path.parent_repeat_group_id).to eq(fi4)

    # Back to root.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup:0:#{fi0},Answer:2:#{fi6}}"
    )
    expect(path.changes).to eq([-1, 0])
    expect(path.parent_repeat_group_id).to be_nil
  end
end
