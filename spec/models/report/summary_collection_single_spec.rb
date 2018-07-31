# tests the singleton case of summary collections, where there is only one subset in the collection
# tests for the multiple case, where there are multiple subsets in the collection, are currently in SummaryCollectionMultipleTest

require "rails_helper"

describe "summary collection with single subset" do
  it "summary should contain question type" do
    prepare_form_and_collection("integer", [0])
    expect(first_summary.qtype.name).to eq("integer")
  end

  describe "integer summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("integer", [10, 7, 6, 1, 1])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq({:mean => 6.0, :max => 10, :min => 1})
    end

    it "should be correct for enumerator" do
      prepare_form("integer", [10, 7, 6, 1, 1])

      enumerator = create(:user, :role_name => :enumerator)
      [10, 7, 6, 1, 1].each{|a| create(:response, :form => @form, :answer_values => [a], :user => enumerator)}

      @collection = Report::SummaryCollectionBuilder.new(@form.questionings, nil, :restrict_to_user => enumerator).build

      expect(headers_and_items(:stat, :stat)).to eq({:mean => 5.0, :max => 10, :min => 1})
    end

    it "should not include nil or blank values" do
      prepare_form_and_collection("integer", [5, nil, "", 2])
      expect(headers_and_items(:stat, :stat)).to eq({:mean => 3.5, :max => 5, :min => 2})
    end

    it "values should be correct type" do
      prepare_form_and_collection("integer", [1])
      items = first_summary.items
      expect(items[0].stat.class).to eq(Float) # mean
      expect(items[1].stat.class).to eq(Integer) # min
      expect(items[2].stat.class).to eq(Integer) # max
    end

    it "null_count should be correct" do
      prepare_form_and_collection("integer", [5, "", "", 2])
      expect(first_summary.null_count).to eq(2)
    end

    it "should be correct with no values" do
      prepare_form_and_collection("integer", [])
      expect(first_summary.items).to eq([])
    end

    it "should be correct with no non-blank values" do
      prepare_form_and_collection("integer", [nil, ""])
      expect(first_summary.items).to eq([])
    end
  end

  describe "counter summary" do
    it "should work like integer" do
      prepare_form("counter", [10, 7, 6, 1, 1])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq({:mean => 6.0, :max => 10, :min => 1})
    end
  end

  describe "decimal summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("decimal", [10.0, 7.2, 6.7, 1.1, 11.5])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq({:mean => 6.25, :max => 10, :min => 1.1})
    end

    it "should be correct with no non-blank values" do
      prepare_form_and_collection("decimal", [nil, ""])
      expect(first_summary.items).to eq([])
    end

    it "values should be correct type" do
      prepare_form_and_collection("decimal", [1])
      items = first_summary.items
      expect(items[0].stat.class).to eq(Float) # mean
      expect(items[1].stat.class).to eq(Float) # min
      expect(items[2].stat.class).to eq(Float) # max
    end

    it "should be able to handle large values" do
      val = 9_999_999_999_999.999_999
      prepare_form_and_collection("decimal", [val])
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq(mean: val, max: val, min: val)
    end
  end

  describe "select_one summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("select_one", %w(Yes No No No Yes))
      @responses.last.destroy
      prepare_collection
      options = @form.questions[0].option_set.options
      expect(headers_and_items(:option, :count)).to eq({options[0] => 1, options[1] => 3})
      expect(headers_and_items(:option, :pct)).to eq({options[0] => 25.0, options[1] => 75.0})
    end

    it "should be correct with multilevel option set" do
      prepare_form_and_collection("multilevel_select_one", [%w(Animal Dog), %w(Animal), %w(Animal Cat), %w(Plant Tulip)])
      animal, plant = @form.questions[0].option_set.options # Top level options
      expect(headers_and_items(:option, :count)).to eq({animal => 3, plant => 1})
      expect(headers_and_items(:option, :pct)).to eq({animal => 75.0, plant => 25.0})
    end

    it "null_count should be correct" do
      prepare_form_and_collection("select_one", ["Yes", "", "No", ""])
      expect(first_summary.null_count).to eq(2)
    end

    it "should still have items if no values" do
      prepare_form_and_collection("select_one", [nil, nil])
      options = @form.questions[0].option_set.options
      expect(headers_and_items(:option, :count)).to eq({options[0] => 0, options[1] => 0})
      expect(headers_and_items(:option, :pct)).to eq({options[0] => 0, options[1] => 0})
    end
  end

  describe "select_multiple summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("select_multiple", [%w(A), %w(B C), %w(A C), %w(C), %w(A)], option_names: %w(A B C))
      @responses.last.destroy
      prepare_collection
      options = @form.questions[0].option_set.options
      expect(headers_and_items(:option, :count)).to eq(
        {options[0] => 2, options[1] => 1, options[2] => 3})
      expect(headers_and_items(:option, :pct)).to eq(
        {options[0] => 50.0, options[1] => 25.0, options[2] => 75.0})
    end

    it "null_count should always be zero" do
      prepare_form_and_collection("select_multiple", [%w(A)], :option_names => %w(A B C))
      expect(first_summary.null_count).to eq(0)
    end
  end

  describe "date summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("date", %w[20131026 20131027 20131027 20131028 20131026])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:date, :count)).to eq(
        Date.parse("20131026") => 1, Date.parse("20131027") => 2, Date.parse("20131028") => 1
      )
      expect(headers_and_items(:date, :pct)).to eq(
        Date.parse("20131026") => 25.0, Date.parse("20131027") => 50.0, Date.parse("20131028") => 25.0
      )
    end

    it "headers should be sorted properly" do
      prepare_form_and_collection("date", %w[20131027 20131027 20131026 20131028])
      expect(first_summary.headers.map { |h| h[:date] })
        .to eq(%w[20131026 20131027 20131028].map { |d| Date.parse(d) })
    end

    it "should work with null values" do
      prepare_form_and_collection("date", ["20131027", nil])
      expect(headers_and_items(:date, :count)).to eq(Date.parse("20131027") => 1)
    end

    it "should work with no responses" do
      prepare_form_and_collection("date", [])
      expect(headers_and_items(:date, :count)).to eq({})
    end

    it "null_count should be correct for" do
      prepare_form_and_collection("date", ["", "20131027", ""])
      expect(first_summary.null_count).to eq(2)
    end
  end

  describe "time summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("time", %w[9:30 10:15 22:15 12:59])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq(mean: "14:00:00", min: "09:30:00", max: "22:15:00")
    end

    it "null_count should be correct" do
      prepare_form_and_collection("time", ["9:30", "", ""])
      expect(first_summary.null_count).to eq(2)
    end

    it "should be correct with no values" do
      prepare_form_and_collection("time", [])
      expect(first_summary.items).to eq([])
    end
  end

  describe "datetime summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("datetime",
        ["2013-10-26 18:45", "2013-10-26 10:15", "2013-10-27 19:00", "2013-10-27 20:00"])
      @responses.last.destroy
      prepare_collection
      expect(headers_and_items(:stat, :stat)).to eq(
        mean: "Oct 27 2013 00:00:00",
        min: "Oct 26 2013 10:15:00",
        max: "Oct 27 2013 19:00:00"
      )
    end

    it "null_count should be correct" do
      prepare_form_and_collection("datetime", ["2013-10-26 9:30", "", ""])
      expect(first_summary.null_count).to eq(2)
    end
  end

  describe "text summary" do
    it "should be correct and ignore deleted values" do
      prepare_form("text", %w[foo bar baz])
      @responses.last.destroy
      prepare_collection
      expect(first_summary.items.map(&:text)).to eq(%w[foo bar])
    end

    it "null_count should work" do
      prepare_form_and_collection("text", ["foo", "", "bar", ""])
      expect(first_summary.null_count).to eq(2)
    end

    it "should work with no values" do
      prepare_form_and_collection("text", [])
      expect(first_summary.items).to eq([])
      expect(first_summary.null_count).to eq(0)
    end

    it "should include response_id in long_text only" do
      prepare_form_and_collection("long_text", %w[foo bar])
      expect(first_summary.items.map(&:response_id).sort).to eq(@form.responses.map(&:id).sort)
    end

    it "items should be in chronological order" do
      responses = prepare_form("text", %w[foo bar baz])

      # change response dates
      responses[1].root_node.c[0].update!(created_at: Time.zone.now + 1.hour)
      responses[2].root_node.c[0].update!(created_at: Time.zone.now - 1.hour)
      @form.reload

      prepare_collection

      # check for correct order
      expect(first_summary.items.map(&:text)).to eq(%w[baz foo bar])
    end
  end

  def prepare_form_and_collection(*args)
    prepare_form(*args)
    prepare_collection
  end

  def prepare_form(qtype, answers, options = {})
    @form = create(:form, {question_types: [qtype], option_names: %w[Yes No]}.merge(options))
    @responses = answers.map { |a| create(:response, form: @form, answer_values: [a]) }
  end

  def prepare_collection
    # second argument is nil since there is no disaggregation question
    @collection = Report::SummaryCollectionBuilder.new(@form.questionings, nil).build
  end

  # gets the first summary in the generated collection
  def first_summary
    # there is only one subset, and there is only one summary per subset, since this is the single case
    @collection.subsets[0].summaries[0]
  end

  # generates a hash of headers to items for testing purposes
  def headers_and_items(header_attrib, item_attrib)
    Hash[*first_summary.headers.each_with_index.map{|h, i| [h[header_attrib], first_summary.items[i].send(item_attrib)]}.flatten(1)]
  end
end
