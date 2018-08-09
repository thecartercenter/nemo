# frozen_string_literal: true

require "rails_helper"

describe Results::Csv::GroupPath do
  let(:path) { described_class.new }

  it "should work with nested groups" do
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be false

    # Start with a nested answer.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer0}"
    )

    # Response and both group levels have changed, hence the 3.
    expect(path.changes).to eq([0, 3])
    expect(path.changed?).to be true

    # Next answer is root-level.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup0,Answer1}"
    )
    expect(path.changes).to eq([-2, 0])
    expect(path.changed?).to be true

    # Next answer is in non-repeat group (no change).
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup0,AnswerGroup2,Answer0}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be false

    # Down to first level of repeat group on new response.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer0}"
    )
    expect(path.changes).to eq([-1, 2])
    expect(path.changed?).to be true

    # No change in group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer1}"
    )
    expect(path.changes).to eq([0, 0])
    expect(path.changed?).to be false

    # Into next item.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup1,Answer0}"
    )
    expect(path.changes).to eq([-1, 1])

    # Into second level nested group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup1,AnswerGroupSet1,AnswerGroup0,Answer0}"
    )
    expect(path.changes).to eq([0, 1])

    # Into first level of later, non-repeat group (non-repeat groups don't count as path changes).
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroup1,Answer0}"
    )
    expect(path.changes).to eq([-2, 0])

    # Back to root.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,Answer2}"
    )
    expect(path.changes).to eq([0, 0])
  end

  it "should work with single depth group" do
    expect(path.changes).to eq([0, 0])

    # Start with a nested answer.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer0}"
    )

    # Response and both group levels have changed, hence the 2.
    expect(path.changes).to eq([0, 2])

    # Next answer is root-level.
    path.process_row(
      "response_id" => "1",
      "ancestry" => "{AnswerGroup0,Answer1}"
    )
    expect(path.changes).to eq([-1, 0])

    # Down to first level group on new response.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer0}"
    )
    expect(path.changes).to eq([-1, 2])

    # No change.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup0,Answer1}"
    )
    expect(path.changes).to eq([0, 0])

    # Into next item.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet0,AnswerGroup1,Answer0}"
    )
    expect(path.changes).to eq([-1, 1])

    # Into later group.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,AnswerGroupSet1,AnswerGroup0,Answer0}"
    )
    expect(path.changes).to eq([-1, 1])

    # Back to root.
    path.process_row(
      "response_id" => "2",
      "ancestry" => "{AnswerGroup0,Answer2}"
    )
    expect(path.changes).to eq([-1, 0])
  end
end
