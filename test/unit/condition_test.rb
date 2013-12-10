require 'test_helper'

class ConditionTest < ActiveSupport::TestCase
  setup do
  end
  
  test "create" do
    q, c = build_condition(:op => 'eq', :value => 5)
    q.save!
  end
  
  test "all fields required" do
    q, c = build_condition(:op => 'eq', :value => nil)
    q.save
    assert_match(/All condition fields are required/, q.errors.messages.values.join)
  end
  
  test "blanks stripped" do
    q, c = build_condition(:op => 'eq', :value => "   ", :option_id => "")
    q.save
    assert_nil(c.value)
    assert_nil(c.option)
  end
  
  test "clean times" do
    q, c = build_condition(:question_types => %w(datetime integer), :op => 'eq', :value => '2013-04-30 2:14pm')
    q.save
    assert_equal('2013-04-30 14:14', c.value)
  end
  
  test "refable qings" do
    # build a condition with a form with a non-refable qtype
    q, c = build_condition(:question_types => [Condition::NON_REFABLE_TYPES.first, 'integer', 'decimal', 'integer'])
    q.save
    assert_equal(q.form.questionings[1..2], c.refable_qings)
  end
  
  test "refable qing types" do
    q, c = build_condition(:question_types => %w(decimal integer text))
    q.save
    assert_equal({q.previous[0].id => 'decimal', q.previous[1].id => 'integer'}, c.refable_qing_types)
  end
  
  test "refable qing option lists" do
    q, c = build_condition(:question_types => %w(select_one integer))

    # retrieve the options for the created select question
    opts = q.previous[0].options

    assert_equal({q.previous[0].id => [['Yes', opts[0].id], ['No', opts[1].id]]}, c.refable_qing_option_lists)
  end
  
  test "applicable operator names" do
    q, c = build_condition(:question_types => %w(select_one integer))
    assert_equal([:eq, :neq], c.applicable_operator_names)
  end
  
  test "verify ordering" do
    q, c = build_condition(:question_types => %w(select_one integer))
    
    # swap question ranks on the sly!
    q.previous[0].rank = 2
    q.rank = 1
    
    assert_raise(ConditionOrderingError){c.verify_ordering}
  end
  
  test "to odk" do
    q, c = build_condition
    assert_equal("/data/q#{q.previous[0].question.id} = #{c.value}", c.to_odk)
    q, c = build_condition(:question_types => %w(select_one integer))
    assert_equal("selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}')", c.to_odk)
    q, c = build_condition(:question_types => %w(select_one integer), :op => 'neq')
    assert_equal("not(selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}'))", c.to_odk)
    q, c = build_condition(:question_types => %w(datetime integer), :op => 'neq', :value => '2013-04-30 2:14pm')
    assert_equal("format-date(/data/q#{q.previous[0].question.id}, '%Y%m%d%H%M') != '201304301414'", c.to_odk)
  end
  
  test "to string" do
    q, c = build_condition
    assert_equal("Question #1 is equal to \"1\"", c.to_s)
  end
  
  private

    def build_condition(params = {})
      clear_objects(Questioning, Question, Form, Optioning, Option, OptionSet)
      f = FactoryGirl.create(:form, :question_types => params.delete(:question_types) || %w(integer integer integer))
      q = f.questionings.last
      
      # building the association this way because doing q.condition = ... causes a weird validation error
      q.build_condition(FactoryGirl.build(:condition, params.merge(:ref_qing => f.questionings.first)).attributes)
      [q, q.condition]
    end
end
