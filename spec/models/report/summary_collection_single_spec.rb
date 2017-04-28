# tests the singleton case of summary collections, where there is only one subset in the collection
# tests for the multiple case, where there are multiple subsets in the collection, are currently in SummaryCollectionMultipleTest

require 'spec_helper'

describe "summary collection with single subset" do
  it "summary should contain question type" do
    prepare_form_and_collection('integer', [0])
    expect(first_summary.qtype.name).to eq('integer')
  end

  it "observer integer summary should be correct" do
    #prepare_form_and_collection('integer', [10, 7, 6, 1, 1])
    prepare_form('integer', [10, 7, 6, 1, 1])

    observer = create(:user, :role_name => :observer)
    [10, 7, 6, 1, 1].each{|a| create(:response, :form => @form, :answer_values => [a], :user => observer)}

    @collection = Report::SummaryCollectionBuilder.new(@form.questionings, nil, :restrict_to_user => observer).build

    expect(headers_and_items(:stat, :stat)).to eq({:mean => 5.0, :max => 10, :min => 1})
  end

  it "integer summary should be correct" do
    prepare_form_and_collection('integer', [10, 7, 6, 1, 1])
    expect(headers_and_items(:stat, :stat)).to eq({:mean => 5.0, :max => 10, :min => 1})
  end

  it "integer summary should not include nil or blank values" do
    prepare_form_and_collection('integer', [5, nil, '', 2])
    expect(headers_and_items(:stat, :stat)).to eq({:mean => 3.5, :max => 5, :min => 2})
  end

  it "integer summary values should be correct type" do
    prepare_form_and_collection('integer', [1])
    items = first_summary.items
    expect(items[0].stat.class).to eq(Float) # mean
    expect(items[1].stat.class).to eq(Fixnum) # min
    expect(items[2].stat.class).to eq(Fixnum) # max
  end

  it "null_count should be correct for integer" do
    prepare_form_and_collection('integer', [5, nil, '', 2])
    expect(first_summary.null_count).to eq(2)
  end

  it "integer summary should be correct with no values" do
    prepare_form_and_collection('integer', [])
    expect(first_summary.items).to eq([])
  end

  it "integer summary should be correct with no non-blank values" do
    prepare_form_and_collection('integer', [nil, ''])
    expect(first_summary.items).to eq([])
  end

  it "decimal summary should be correct in normal case" do
    prepare_form_and_collection('decimal', [10.0, 7.2, 6.7, 1.1, 11.5])
    expect(headers_and_items(:stat, :stat)).to eq({:mean => 7.3, :max => 11.5, :min => 1.1})
  end

  it "decimal summary should be correct with no non-blank values" do
    prepare_form_and_collection('decimal', [nil, ''])
    expect(first_summary.items).to eq([])
  end

  it "decimal summary values should be correct type" do
    prepare_form_and_collection('decimal', [1])
    items = first_summary.items
    expect(items[0].stat.class).to eq(Float) # mean
    expect(items[1].stat.class).to eq(Float) # min
    expect(items[2].stat.class).to eq(Float) # max
  end

  it "select_one summary should be correct in normal case" do
    prepare_form_and_collection('select_one', %w(Yes No No No))
    options = @form.questions[0].option_set.options
    expect(headers_and_items(:option, :count)).to eq({options[0] => 1, options[1] => 3})
    expect(headers_and_items(:option, :pct)).to eq({options[0] => 25.0, options[1] => 75.0})
  end

  it "select_one summary should be correct with multilevel option set" do
    prepare_form_and_collection('multilevel_select_one', [%w(Animal Dog), %w(Animal), %w(Animal Cat), %w(Plant Tulip)])
    animal, plant = @form.questions[0].option_set.options # Top level options
    expect(headers_and_items(:option, :count)).to eq({animal => 3, plant => 1})
    expect(headers_and_items(:option, :pct)).to eq({animal => 75.0, plant => 25.0})
  end

  it "null_count should be correct for select_one" do
    prepare_form_and_collection('select_one', ['Yes', nil, 'No', nil])
    expect(first_summary.null_count).to eq(2)
  end

  it "select_one summary should still have items if no values" do
    prepare_form_and_collection('select_one', [nil, nil])
    options = @form.questions[0].option_set.options
    expect(headers_and_items(:option, :count)).to eq({options[0] => 0, options[1] => 0})
    expect(headers_and_items(:option, :pct)).to eq({options[0] => 0, options[1] => 0})
  end

  it "select_multiple summary should be correct in normal case" do
    prepare_form_and_collection('select_multiple', [%w(A), %w(B C), %w(A C), %w(C)], :option_names => %w(A B C))
    options = @form.questions[0].option_set.options
    expect(headers_and_items(:option, :count)).to eq({options[0] => 2, options[1] => 1, options[2] => 3})
    expect(headers_and_items(:option, :pct)).to eq({options[0] => 50.0, options[1] => 25.0, options[2] => 75.0})
  end

  it "null_count should always be zero for select_multiple" do
    prepare_form_and_collection('select_multiple', [%w(A)], :option_names => %w(A B C))
    expect(first_summary.null_count).to eq(0)
  end

  it "date question summary should be correct in normal case" do
    prepare_form_and_collection('date', %w(20131026 20131027 20131027 20131028))
    expect(headers_and_items(:date, :count)).to eq({Date.parse('20131026') => 1, Date.parse('20131027') => 2, Date.parse('20131028') => 1})
    expect(headers_and_items(:date, :pct)).to eq({Date.parse('20131026') => 25.0, Date.parse('20131027') => 50.0, Date.parse('20131028') => 25.0})
  end

  it "date question summary headers should be sorted properly" do
    prepare_form_and_collection('date', %w(20131027 20131027 20131026 20131028))
    expect(first_summary.headers.map{|h| h[:date]}).to eq(%w(20131026 20131027 20131028).map{|d| Date.parse(d)})
  end

  it "date question summary should work with null values" do
    prepare_form_and_collection('date', ['20131027', nil])
    expect(headers_and_items(:date, :count)).to eq({Date.parse('20131027') => 1})
  end

  it "date question summary should work with no responses" do
    prepare_form_and_collection('date', [])
    expect(headers_and_items(:date, :count)).to eq({})
  end

  it "null_count should be correct for date question summary" do
    prepare_form_and_collection('date', [nil, '20131027', nil])
    expect(first_summary.null_count).to eq(2)
  end

  it "time question summary should be correct in normal case" do
    prepare_form_and_collection('time', %w(9:30 10:15 22:15))
    expect(headers_and_items(:stat, :stat)).to eq({mean: '14:00', min: '09:30', max: '22:15'})
  end

  it "null_count should be correct for time" do
    prepare_form_and_collection('time', ['9:30', nil, nil])
    expect(first_summary.null_count).to eq(2)
  end

  it "time summary should be correct with no values" do
    prepare_form_and_collection('time', [])
    expect(first_summary.items).to eq([])
  end

  it "datetime summary should be correct in normal case" do
    prepare_form_and_collection('datetime', ['2013-10-26 18:45', '2013-10-26 10:15', '2013-10-27 19:00'])
    expect(headers_and_items(:stat, :stat)).to eq(
      mean: 'Oct 27 2013 00:00',
      min: 'Oct 26 2013 10:15',
      max: 'Oct 27 2013 19:00'
    )
  end

  it "null_count should be correct for datetime" do
    prepare_form_and_collection('datetime', ['2013-10-26 9:30', nil, nil])
    expect(first_summary.null_count).to eq(2)
  end

  it "text summary should be correct in normal case" do
    prepare_form_and_collection('text', ['foo', 'bar'])
    expect(first_summary.items.map(&:text)).to eq(['foo', 'bar'])
  end

  it "null_count should work for text summary" do
    prepare_form_and_collection('text', ['foo', nil, 'bar', ''])
    expect(first_summary.null_count).to eq(2)
  end

  it "text summary should work with no values" do
    prepare_form_and_collection('text', [])
    expect(first_summary.items).to eq([])
    expect(first_summary.null_count).to eq(0)
  end

  it "long_text summary should include response_id" do
    prepare_form_and_collection('long_text', ['foo', 'bar'])
    expect(first_summary.items.map(&:response_id).sort).to eq(@form.responses.map(&:id).sort)
  end

  it "text summary items should be in chronological order" do
    responses = prepare_form('text', ['foo', 'bar', 'baz'])

    # change response dates
    responses[1].answers[0].update_attributes!(created_at: Time.now + 1.hour)
    responses[2].answers[0].update_attributes!(created_at: Time.now - 1.hour)
    @form.reload

    prepare_collection

    # check for correct order
    expect(first_summary.items.map(&:text)).to eq(%w(baz foo bar))
  end

  def prepare_form_and_collection(*args)
    prepare_form(*args)
    prepare_collection
  end

  def prepare_form(qtype, answers, options = {})
    @form = create(:form, {:question_types => [qtype], :option_names => %w(Yes No)}.merge(options))
    answers.map{|a| create(:response, :form => @form, :answer_values => [a])}
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
