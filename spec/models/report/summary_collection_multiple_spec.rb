# This tests the general case of summary collections, where there are multiple subsets in the collection
# makes sure that the data is disaggregated properly
# tests for the singleton case, where there is only one subset in the collection, are currently in SummaryCollectionSingleTest

require 'rails_helper'

describe "summary collection with multiple subsets" do
 it "collection should have proper disagg values" do
    # build a form with two questions: the one we want to analyze and the one we want to disaggregate by
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4], 'b' => [8,9]})
    options = @form.questionings[1].options
    expect(@collection.subsets[0].disagg_value).to eq(options[0])
    expect(@collection.subsets[1].disagg_value).to eq(options[1])
  end

 it "collections with integer questions should have correct summaries" do
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4,6], 'b' => [8,9]})
    expect(header_names_for_disagg_value('a')).to eq(%w(Average Minimum Maximum))
    expect(header_names_for_disagg_value('b')).to eq(%w(Average Minimum Maximum))
    expect(items_for_disagg_value('a', :stat)).to eq([3.25, 1, 6])
    expect(items_for_disagg_value('b', :stat)).to eq([8.5, 8, 9])
  end

 it "collections with select_one questions should have correct summaries" do
    prepare_form_and_collection('select_one', 'select_one', {'a' => ['red', 'red', 'blue'], 'b' => ['blue', 'red', 'blue', 'blue']})
    expect(header_names_for_disagg_value('a')).to eq(%w(red blue green))
    expect(header_names_for_disagg_value('b')).to eq(%w(red blue green))
    expect(items_for_disagg_value('a', :count)).to eq([2, 1, 0])
    expect(items_for_disagg_value('b', :count)).to eq([1, 3, 0])
  end

 it "collections with select_multiple questions should have correct summaries" do
    prepare_form_and_collection('select_multiple', 'select_one',
      {'a' => [['red'], ['red', 'green'], []], 'b' => [['blue', 'red'], ['blue', 'green']]})

    expect(header_names_for_disagg_value('a')).to eq(%w(red blue green))
    expect(header_names_for_disagg_value('b')).to eq(%w(red blue green))
    expect(items_for_disagg_value('a', :count)).to eq([2, 0, 1])
    expect(items_for_disagg_value('b', :count)).to eq([1, 2, 1])
  end

 it "collections with date questions should have correct summaries" do
    prepare_form_and_collection('date', 'select_one',
      {'a' => %w(2012-10-26 2011-07-22 2012-10-26), 'b' => %w(2013-07-22 2012-9-22 2013-07-22 2013-07-22)})

    # check that headers are correct and in correct order
    expect(header_names_for_disagg_value('a')).to eq(['Jul 22 2011', 'Oct 26 2012'])
    expect(header_names_for_disagg_value('b')).to eq(['Sep 22 2012', 'Jul 22 2013'])

    # check that tallies are correct
    expect(items_for_disagg_value('a', :count)).to eq([1, 2])
    expect(items_for_disagg_value('b', :count)).to eq([1, 3])
  end

 it "collections with text questions should have correct summaries" do
    prepare_form_and_collection('text', 'select_one',
      {'a' => %w(foo bar baz), 'b' => %w(bing bop) + [""]}, :dont_shuffle => true)

    # check that items are correct
    expect(items_for_disagg_value('a', :text)).to eq(%w(foo bar baz))
    expect(items_for_disagg_value('b', :text)).to eq(%w(bing bop))
    expect(null_count_for_disagg_value('a')).to eq(0)
    expect(null_count_for_disagg_value('b')).to eq(1)
  end

 it "collection subsets should be correct if no answers for one of the options" do
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4,6], 'b' => [8,9], 'c' => []})
    options = @form.questionings[1].options

    # subset should still be created
    expect(@collection.subsets[2].disagg_value).to eq(options[2])

    # but should be marked no_data
    expect(@collection.subsets[2].no_data?).to eq(true)
  end

 it "collection should work if there are no answers at all" do
    prepare_form_and_collection('integer', 'select_one', {'a' => [], 'b' => []})

    # collection should be marked no_data
    expect(@collection.no_data?).to eq(true)
  end

 it "the disaggregation question should not be included in the report output" do
    # since otherwise it would always be 100% in one column and 0% in the others
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4,6], 'b' => [8,9], 'c' => []})

    # there should only be one summary (integer type) in each subset. the select_one question should not be included.
    expect(@collection.subsets[0].summaries.map{|s| s.qtype.name}).to eq(%w(integer))
  end

 it "a nil disaggregation value should still have a subset" do
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4,6], 'b' => [8,9], nil => [2,5]})
    expect(header_names_for_disagg_value('a')).to eq(%w(Average Minimum Maximum))
    expect(header_names_for_disagg_value('b')).to eq(%w(Average Minimum Maximum))
    expect(header_names_for_disagg_value(nil)).to eq(%w(Average Minimum Maximum))
    expect(items_for_disagg_value('a', :stat)).to eq([3.25, 1, 6])
    expect(items_for_disagg_value('b', :stat)).to eq([8.5, 8, 9])
    expect(items_for_disagg_value(nil, :stat)).to eq([3.5, 2, 5])
  end

  def prepare_form_and_collection(*args)
    prepare_form(*args)
    prepare_collection
  end

  def prepare_form(analyze_type, dissag_type, answers_by_dissag_value, options = {})
    # create form
    @form = create(:form)

    # if the analyze question is a select type, use red blue green as option set (ignored otherwise)
    analyze_q = create(:question, :qtype_name => analyze_type, :option_names => %w(red blue green))

    # add the disagg question
    disagg_q = create(:question, :qtype_name => dissag_type, :option_names => answers_by_dissag_value.keys.compact)

    create(:questioning, question: analyze_q, form: @form)
    create(:questioning, question: disagg_q, form: @form)

    @form.save!
    @form.reload

    # convert answers to array of arrays
    answers = answers_by_dissag_value.map{|dissag_value, values| values.map{|v| [v, dissag_value]}}.flatten(1)

    # randomize to make sure they're untangled properly later
    answers.shuffle! unless options[:dont_shuffle]

    # build the responses
    answers.each{|a| create(:response, :form => @form, :answer_values => a)}
  end

  def prepare_collection
    # pass the full questionings array, and the disaggregation questioning, which is the last one
    @collection = Report::SummaryCollectionBuilder.new(@form.questionings, @form.questionings.last).build
  end

  def subsets_by_disagg_value
    @subsets_by_disagg_value ||= @collection.subsets.index_by{|s| s.disagg_value.try(:name)}
  end

  def header_names_for_disagg_value(val)
    # the question we're interested in is always rank 1
    subsets_by_disagg_value[val].summaries.detect{|s| s.questioning.rank == 1}.headers.map{|h| h[:name]}
  end

  def items_for_disagg_value(val, item_attrib)
    subsets_by_disagg_value[val].summaries.detect{|s| s.questioning.rank == 1}.items.map{|i| i.send(item_attrib)}
  end

  def null_count_for_disagg_value(val)
    subsets_by_disagg_value[val].summaries.detect{|s| s.questioning.rank == 1}.null_count
  end
end
