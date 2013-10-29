# tests the general case of summary collections, where there are multiple subsets in the collection
# makes sure that the data is disaggregated properly
# tests for the singleton case, where there is only one subset in the collection, are currently in QuestionSummaryTest

require 'test_helper'
require 'unit/report/report_test_helper'

class Report::SummaryCollectionTest < ActiveSupport::TestCase
  test "collection subsets should have proper disagg values" do
    # build a form with two questions: the one we want to analyze and the one we want to disaggregate by
    prepare_form_and_collection('integer', 'select_one', {'a' => [1,2,4], 'b' => [8,9]})
    options = @form.questionings[1].options
    assert_equal(options[0], @collection.subsets[0].disagg_value)
    assert_equal(options[1], @collection.subsets[1].disagg_value)
  end

  test "what happens if options with no answers" do end

  test "the disaggregation question should not be included in the report output" do
    # since otherwise it would always be 100% in one column and 0% in the others
  end

  private
    def prepare_form_and_collection(*args)
      prepare_form(*args)
      prepare_collection
    end

    def prepare_form(analyze_type, dissag_type, answers_by_dissag_value)
      # create form with just the analysis type
      @form = FactoryGirl.create(:form, :question_types => [analyze_type])

      # add the disagg question
      disagg_q = FactoryGirl.create(:question, :qtype_name => dissag_type, :option_names => answers_by_dissag_value.keys)
      @form.questions << disagg_q
      @form.save!

      # convert answers to array of arrays
      answers = answers_by_dissag_value.map{|dissag_value, values| values.map{|v| [v, dissag_value]}}.flatten(1)

      # randomize to make sure they're untangled properly later
      answers.shuffle!

      # build the responses
      answers.each{|a| FactoryGirl.create(:response, :form => @form, :_answers => a)}
    end

    def prepare_collection
      # pass the full questionings array, and the disaggregation questioning, which is the last one
      @collection = Report::SummaryCollectionBuilder.new(@form.questionings, @form.questionings.last).build
    end
end