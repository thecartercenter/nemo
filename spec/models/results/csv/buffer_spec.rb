# frozen_string_literal: true

require "rails_helper"

describe Results::Csv::Buffer do
  # Column to index mappings for fake header_map. In reality, setting these indices up is more complex, but
  # we're just stubbing them here.
  let(:indices) do
    {
      "response_id" => 0,
      "form_name" => 1,
      "group1_rank" => 2,
      "group1_inst_num" => 3,
      "group2_rank" => 4,
      "group2_inst_num" => 5,
      "parent_group_name" => 6,
      "parent_group_depth" => 7,
      "q1" => 8,
      "q2" => 9,
      "q3_1:lat" => 10,
      "q3_1:lng" => 11,
      "q3_2" => 12,
      "q3_1_1" => 13,
      "q3_1_2" => 14,
      "q99" => 15
    }
  end
  let(:header_map) do
    double(common_headers: %w[response_id form_name], count: indices.size)
  end
  let(:buffer) do
    described_class.new(
      max_depth: 2,
      header_map: header_map
    )
  end

  # Simple dummy that saves the last thing passed to it
  class DummyCSV
    attr_accessor :last_row
    def <<(row)
      self.last_row = row.dup # Row may get changed again before we look at it.
    end
  end

  before do
    allow(header_map).to receive(:index_for) { |h| indices[h] }
    buffer.prepare
    buffer.csv = DummyCSV.new
  end

  # Proceeds through a series of rows simulating what would be passed by the Generator.
  # The data represented by the rows consists of 4 responses to 2 different forms.
  # See the comments below for more details.
  it "should process properly" do
    # Initial call.
    csv_row = process_row(
      "response_id" => "1",
      "form_name" => "form1",
      "decoy" => "95406",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )
    expect(csv_row).to be_nil

    buffer.write("q1", "val1")

    # No change.
    csv_row = process_row(
      "response_id" => "1",
      "form_name" => "form1",
      "decoy" => "22399",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )
    expect(csv_row).to be_nil

    buffer.write("q2", "val2")

    # Response ID change.
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "13405",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )

    # CSV row for response 1 should be dumped.
    expect(csv_row).to eq([
      "1",          # response_id
      "form1",      # form_name
      nil,          # group1_rank
      nil,          # group1_inst_num
      nil,          # group2_rank
      nil,          # group2_inst_num
      nil,          # parent_group_name
      0,            # parent_group_depth
      "val1",       # q1
      "val2",       # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil           # q99
    ])

    buffer.write("q1", "val3")

    # No change.
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "79163",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )
    expect(csv_row).to be_nil

    buffer.write("q2", "val4")

    # Enter 1st level group
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "49445",
      "group1_rank" => "3",
      "group1_inst_num" => "1",
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => "people",
      "parent_group_depth" => 1
    )

    # CSV row for response 2, level 0 should be dumped.
    expect(csv_row).to eq([
      "2",          # response_id
      "form1",      # form_name
      nil,          # group1_rank
      nil,          # group1_inst_num
      nil,          # group2_rank
      nil,          # group2_inst_num
      nil,          # parent_group_name
      0,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil           # q99
    ])

    buffer.write("q3_1:lat", "val5")
    buffer.write("q3_1:lng", "val6")

    # No change.
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "44804",
      "group1_rank" => "3",
      "group1_inst_num" => "1",
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => "people",
      "parent_group_depth" => 1
    )
    expect(csv_row).to be_nil

    buffer.write("q3_2", "val7")

    # Instance num change.
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "50631",
      "group1_rank" => "3",
      "group1_inst_num" => "2",
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => "people",
      "parent_group_depth" => 1
    )

    # CSV row for response 2, group 3, instance 1 should be dumped.
    expect(csv_row).to eq([
      "2",          # response_id
      "form1",      # form_name
      "3",          # group1_rank
      "1",          # group1_inst_num
      nil,          # group2_rank
      nil,          # group2_inst_num
      "people",     # parent_group_name
      1,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val5",       # q3_1:lat
      "val6",       # q3_1:lng
      "val7",       # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil           # q99
    ])

    buffer.write("q3_1:lat", "val8")
    buffer.write("q3_1:lng", "val9")

    # Enter 2nd level group
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "23353",
      "group1_rank" => "3",
      "group1_inst_num" => "2",
      "group2_rank" => "4",
      "group2_inst_num" => "1",
      "parent_group_name" => "eyes",
      "parent_group_depth" => 2
    )

    # CSV row for response 2, group 3, instance 2 should be dumped.
    expect(csv_row).to eq([
      "2",          # response_id
      "form1",      # form_name
      "3",          # group1_rank
      "2",          # group1_inst_num
      nil,          # group2_rank
      nil,          # group2_inst_num
      "people",     # parent_group_name
      1,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val8",       # q3_1:lat
      "val9",       # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      nil           # q99
    ])

    buffer.write("q3_1_1", "val10")

    # No change.
    csv_row = process_row(
      "response_id" => "2",
      "form_name" => "form1",
      "decoy" => "87078",
      "group1_rank" => "3",
      "group1_inst_num" => "2",
      "group2_rank" => "4",
      "group2_inst_num" => "1",
      "parent_group_name" => "eyes",
      "parent_group_depth" => 2
    )
    expect(csv_row).to be_nil

    buffer.write("q3_1_2", "val11")

    # Response ID and form change.
    csv_row = process_row(
      "response_id" => "3",
      "form_name" => "form2",
      "decoy" => "68083",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )

    # CSV row for response 2, group 3, instance 2, group 1, instance 1 should be dumped.
    expect(csv_row).to eq([
      "2",          # response_id
      "form1",      # form_name
      "3",          # group1_rank
      "2",          # group1_inst_num
      "4",          # group2_rank
      "1",          # group2_inst_num
      "eyes",       # parent_group_name
      2,            # parent_group_depth
      "val3",       # q1
      "val4",       # q2
      "val8",       # q3_1:lat
      "val9",       # q3_1:lng
      nil,          # q3_2
      "val10",      # q3_1_1
      "val11",      # q3_1_2
      nil           # q99
    ])

    # q2 shared by both forms
    buffer.write("q2", "val12")

    # No change.
    csv_row = process_row(
      "response_id" => "3",
      "form_name" => "form2",
      "decoy" => "29325",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )
    expect(csv_row).to be_nil

    # q99 on form2 only. Also testing overwrite when append not given.
    buffer.write("q99", "junk")
    buffer.write("q99", "val13")

    # Response ID change.
    csv_row = process_row(
      "response_id" => "4",
      "form_name" => "form2",
      "decoy" => "56353",
      "group1_rank" => nil,
      "group1_inst_num" => nil,
      "group2_rank" => nil,
      "group2_inst_num" => nil,
      "parent_group_name" => nil,
      "parent_group_depth" => 0
    )

    # CSV row for response 3 should be dumped.
    expect(csv_row).to eq([
      "3",          # response_id
      "form2",      # form_name
      nil,          # group1_rank
      nil,          # group1_inst_num
      nil,          # group2_rank
      nil,          # group2_inst_num
      nil,          # parent_group_name
      0,            # parent_group_depth
      nil,          # q1
      "val12",      # q2
      nil,          # q3_1:lat
      nil,          # q3_1:lng
      nil,          # q3_2
      nil,          # q3_1_1
      nil,          # q3_1_2
      "val13"       # q99
    ])

    # Appends can happen with select_multiple
    buffer.write("q2", "val14", append: true)
    buffer.write("q2", "val15", append: true)

    csv_row = finish

    # CSV row for response 4 should be dumped.
    expect(csv_row).to eq([
      "4",           # response_id
      "form2",       # form_name
      nil,           # group1_rank
      nil,           # group1_inst_num
      nil,           # group2_rank
      nil,           # group2_inst_num
      nil,           # parent_group_name
      0,             # parent_group_depth
      nil,           # q1
      "val14;val15", # q2
      nil,           # q3_1:lat
      nil,           # q3_1:lng
      nil,           # q3_2
      nil,           # q3_1_1
      nil,           # q3_1_2
      nil            # q99
    ])
  end

  # Sends the given row to the Buffer and watches if a CSV row gets written.
  # Returns the row if so, else returns nil.
  # The class is setup this way to save constant re-allocation of the buffer array.
  def process_row(row)
    # Reset the dummy CSV so we will now if the buffer dumped a fresh row
    buffer.csv.last_row = nil
    buffer.process_row(row)
    buffer.csv.last_row
  end

  def finish
    buffer.csv.last_row = nil
    buffer.finish
    buffer.csv.last_row
  end
end
