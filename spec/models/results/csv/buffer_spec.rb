# frozen_string_literal: true

require "rails_helper"

describe Results::CSV::Buffer do
  # Column to index mappings for fake header_map. In reality, setting these indices up is more complex, but
  # we're just stubbing them here.
  let(:indices) do
    {
      "source" => 0,
      "form_name" => 1,
      "parent_group_name" => 2,
      "parent_group_depth" => 3,
      "q1" => 4,
      "q2" => 5,
      "q3_1:lat" => 6,
      "q3_1:lng" => 7,
      "q3_2" => 8,
      "q3_1_1" => 9,
      "q3_1_2" => 10,
      "q4" => 11,
      "q99" => 12
    }
  end
  let(:header_map) do
    # We are deliberately leaving out response_id since it's confusing since it relates to group_path
    # computation which we are stubbing out here. We just want to test that common_headers
    # get written out properly.
    double(common_headers: %w[source form_name], count: indices.size)
  end
  let(:buffer) { described_class.new(header_map: header_map) }
  let(:group_path) { Results::CSV::GroupPath.new }
  let!(:people) { create(:qing_group, group_name: "People", repeatable: true) }
  let!(:pets) { create(:qing_group, group_name: "Pets", repeatable: true) }

  # Simple dummy that saves rows that get passed to it.
  class DummyCSV
    attr_accessor :rows

    def <<(row)
      rows << row.dup # Row may get changed again before we look at it.
    end
  end

  before do
    allow(header_map).to receive(:index_for) { |h| indices[h] }

    # We stub group_path to an object we control so we can manipulate the changes array without
    # re-testing GroupPath's functionality.
    allow(group_path).to receive(:process_row).and_return(nil)
    allow(buffer).to receive(:group_path).and_return(group_path)
    buffer.csv = DummyCSV.new
  end

  # Proceeds through a series of rows simulating what would be passed by the Generator.
  # The data represented by the rows consists of 4 responses to 2 different forms.
  # See the comments below for more details.
  it "should process nested groups properly" do
    # Initial call, assuming top level answer.
    stub_group_path_changes(0, 1, parent_group: nil)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q1", "val1")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: nil)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q2", "val2")

    # Response ID change.
    stub_group_path_changes(-1, 1, parent_group: nil)
    output_rows = process_row("source" => "sms", "form_name" => "form1")

    # CSV row for response 1 should be dumped.
    expect(output_rows).to eq([[
      "web",        # source
      "form1",      # form_name
      nil,          # parent_group_name
      0,            # parent_group_depth
      "val1",       # q1
      "val2",       # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil,          # q4
      nil           # q99
    ]])

    buffer.write("q1", "val3")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: nil)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q2", "val4")

    # Enter 1st level group
    stub_group_path_changes(0, 1, parent_group: people)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1:lat", "val5")
    buffer.write("q3_1:lng", "val6")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: people)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_2", "val7")

    # New instance of 1st level group.
    stub_group_path_changes(-1, 1, parent_group: people)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1:lat", "val8")
    buffer.write("q3_1:lng", "val9")

    # We deliberately don't write to q3_2 in this instance. It should be blank in the output.

    # Enter 2nd level group
    stub_group_path_changes(0, 1, parent_group: pets)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_1", "val10")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: pets)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_2", "val11")

    # Back to top level (2 level jump, important to test this)
    stub_group_path_changes(-2, 0, parent_group: nil)
    output_rows = process_row("source" => "sms", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q4", "val12")

    # Response ID and form change.
    stub_group_path_changes(-1, 1, parent_group: nil)
    output_rows = process_row("source" => "odk", "form_name" => "form2")

    # Four rows should now be dumped, and val12 should be included in all dumped rows.
    expect(output_rows).to eq([[
      # response 2, level 0
      "sms",        # source
      "form1",      # form_name
      nil,          # parent_group_name
      0,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val12",      # q4
      nil           # q99
    ], [
      # response 2, group 3, instance 1
      "sms",        # source
      "form1",      # form_name
      "People",     # parent_group_name
      1,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val5",       # q3_1:lat
      "val6",       # q3_1:lng
      "val7",       # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val12",      # q4
      nil           # q99
    ], [
      # response 2, group 3, instance 2
      "sms",        # source
      "form1",      # form_name
      "People",     # parent_group_name
      1,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val8",       # q3_1:lat
      "val9",       # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val12",      # q4
      nil           # q99
    ], [
      # response 2, group 3, instance 2, group 1, instance 1
      "sms",        # source
      "form1",      # form_name
      "Pets",       # parent_group_name
      2,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val8",       # q3_1:lat
      "val9",       # q3_1:lng
      nil,          # q3_2
      "val10",      # q3_1_1
      "val11",      # q3_1_2
      "val12",      # q4
      nil           # q99
    ]])

    # q2 shared by both forms
    buffer.write("q2", "val13")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: nil)
    output_rows = process_row("source" => "odk", "form_name" => "form2")
    expect(output_rows).to be_empty

    # q99 on form2 only. Also testing overwrite when append not given.
    buffer.write("q99", "junk")
    buffer.write("q99", "val14")

    # Response ID change.
    stub_group_path_changes(-1, 1, parent_group: nil)
    output_rows = process_row("source" => "sms", "form_name" => "form2")

    # CSV row for response 3 should be dumped.
    expect(output_rows).to eq([[
      "odk",        # source
      "form2",      # form_name
      nil,          # parent_group_name
      0,            # parent_group_depth
      nil,          # q1
      "val13",      # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil,          # q4
      "val14"       # q99
    ]])

    # Appends can happen with select_multiple
    buffer.write("q2", "val15", append: true)
    buffer.write("q2", "val16", append: true)

    output_rows = finish

    # CSV row for response 4 should be dumped.
    expect(output_rows).to eq([[
      "sms",         # source
      "form2",       # form_name
      nil,           # parent_group_name
      0,             # parent_group_depth
      nil,           # q1
      "val15;val16", # q2
      nil,           # q3_1:lat
      nil,           # q3_1:lng
      nil,           # q3_2
      nil,           # q3_1_1
      nil,           # q3_1_2
      nil,           # q4
      nil            # q99
    ]])
  end

  it "should process properly when the first row is an answer from a nested group" do
    # Initial call, assuming nested answer.
    stub_group_path_changes(0, 3, parent_group: pets)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_1", "val1")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: pets)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_2", "val2")

    # New instance of 2nd level group.
    stub_group_path_changes(-1, 1, parent_group: pets)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_1", "val3")

    # No group path change.
    stub_group_path_changes(0, 0, parent_group: pets)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_2", "val4")

    # Down to first level of nesting.
    stub_group_path_changes(-1, 0, parent_group: people)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_2", "val5")

    # Back to top level.
    stub_group_path_changes(-1, 0, parent_group: nil)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q4", "val6")

    # Response ID change.
    stub_group_path_changes(-1, 1, parent_group: nil)
    output_rows = process_row("source" => "sms", "form_name" => "form1")

    # Should be 1 row for top level, 1 row for People, 2 rows for Pets
    expect(output_rows).to eq([[
      "web",        # source
      "form1",      # form_name
      nil,          # parent_group_name
      0,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val6",       # q4
      nil           # q99
    ], [
      "web",        # source
      "form1",      # form_name
      "People",     # parent_group_name
      1,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      "val5",       # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val6",       # q4
      nil           # q99
    ], [
      "web",        # source
      "form1",      # form_name
      "Pets",       # parent_group_name
      2,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      "val5",       # q3_2
      "val1",       # q3_1_1
      "val2",       # q3_1_2
      "val6",       # q4
      nil           # q99
    ], [
      "web",        # source
      "form1",      # form_name
      "Pets",       # parent_group_name
      2,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      "val5",       # q3_2
      "val3",       # q3_1_1
      "val4",       # q3_1_2
      "val6",       # q4
      nil           # q99
    ]])

    buffer.write("q1", "val7")

    output_rows = finish

    # Separate response.
    expect(output_rows).to eq([[
      "sms",         # source
      "form1",       # form_name
      nil,           # parent_group_name
      0,             # parent_group_depth
      "val7",        # q1
      nil,           # q2
      nil,           # q3_1:lat
      nil,           # q3_1:lng
      nil,           # q3_2
      nil,           # q3_1_1
      nil,           # q3_1_2
      nil,           # q4
      nil            # q99
    ]])
  end

  it "should process properly when there is no data from 1st level" do
    # Initial call, assuming nested answer.
    stub_group_path_changes(0, 3, parent_group: pets)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q3_1_1", "val1")

    # Back to top level.
    stub_group_path_changes(-2, 0, parent_group: nil)
    output_rows = process_row("source" => "web", "form_name" => "form1")
    expect(output_rows).to be_empty

    buffer.write("q4", "val5")

    output_rows = finish

    # No row for level 1 (People)
    expect(output_rows).to eq([[
      "web",        # source
      "form1",      # form_name
      nil,          # parent_group_name
      0,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val5",       # q4
      nil           # q99
    ], [
      "web",        # source
      "form1",      # form_name
      "Pets",       # parent_group_name
      2,            # parent_group_depth
      nil,          # q1
      nil,          # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      "val1",       # q3_1_1
      nil,          # q3_1_2
      "val5",       # q4
      nil           # q99
    ]])
  end

  # Sends the given row to the Buffer and watches if a CSV row gets written.
  # Returns the row if so, else returns nil.
  # The class is setup this way to save constant re-allocation of the buffer array.
  def process_row(row)
    # Reset the dummy CSV so we will now if the buffer dumped a fresh row
    buffer.csv.rows = []
    buffer.process_row(row)
    buffer.csv.rows
  end

  def finish
    buffer.csv.rows = []
    buffer.finish
    buffer.csv.rows
  end

  def stub_group_path_changes(deletions, additions, parent_group:)
    allow(group_path).to receive(:changes).and_return([deletions, additions])
    allow(group_path).to receive(:parent_repeat_group_id).and_return(parent_group&.id)
  end
end
