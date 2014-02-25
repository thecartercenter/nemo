require 'test_helper'

# tests for standardizable functionality as applied to forms
class StandardizableFormTest < ActiveSupport::TestCase

  test "creating standard form should create standard questions and questionings" do
    # this factory includes some default questions
    f = FactoryGirl.create(:form, :is_standard => true)
    assert(f.reload.questions.all?(&:is_standard?))
    assert(f.questionings.all?(&:is_standard?))
  end

  test "adding questions to a std form should create standard questions and questionings" do
    f = FactoryGirl.create(:form, :is_standard => true)
    f.questions << FactoryGirl.create(:question, :is_standard => true)
    assert(f.reload.questions.all?(&:is_standard?))
    assert(f.questionings.all?(&:is_standard?))
  end

  test "replicating form within mission should avoid name conflict" do
    f = FactoryGirl.create(:form, :name => "Myform", :question_types => %w(integer select_one))
    f2 = f.replicate(:mode => :clone)
    assert_equal('Myform 2', f2.name)
    f3 = f2.replicate(:mode => :clone)
    assert_equal('Myform 3', f3.name)
    f4 = f3.replicate(:mode => :clone)
    assert_equal('Myform 4', f4.name)
  end

  test "replicating form within mission should produce different questionings but same questions and option set" do
    f = FactoryGirl.create(:form, :question_types => %w(integer select_one))
    f2 = f.replicate(:mode => :clone)
    assert_not_equal(f.questionings.first, f2.questionings.first)

    # questionings should point to proper form
    assert_equal(f.questionings[0].form, f)
    assert_equal(f2.questionings[0].form, f2)

    # questions and option sets should be same
    assert_equal(f.questions, f2.questions)
    assert_not_nil(f2.questions[1].option_set)
    assert_equal(f.questions[1].option_set, f2.questions[1].option_set)
  end

  test "replicating a standard form should do a deep copy" do
    f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => true)
    f2 = f.replicate(:mode => :to_mission, :mission => get_mission)

    # mission should now be set and should not be standard
    assert(!f2.is_standard)
    assert_equal(get_mission, f2.mission)

    # all objects should be distinct
    assert_not_equal(f, f2)
    assert_not_equal(f.questionings[0], f2.questionings[0])
    assert_not_equal(f.questionings[0].question, f2.questionings[0].question)
    assert_not_equal(f.questionings[0].question.option_set, f2.questionings[0].question.option_set)
    assert_not_equal(f.questionings[0].question.option_set.optionings[0], f2.questionings[0].question.option_set.optionings[0])
    assert_not_equal(f.questionings[0].question.option_set.optionings[0].option, f2.questionings[0].question.option_set.optionings[0].option)

    # but properties should be same
    assert_equal(f.questionings[0].rank, f2.questionings[0].rank)
    assert_equal(f.questionings[0].question.code, f2.questionings[0].question.code)
    assert_equal(f.questionings[0].question.option_set.optionings[0].option.name, f2.questionings[0].question.option_set.optionings[0].option.name)
  end

  test "replicating form with conditions should produce correct new conditions" do
    f = FactoryGirl.create(:form, :question_types => %w(integer select_one))

    # create condition
    f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1)

    # replicate and test
    f2 = f.replicate(:mode => :clone)

    # questionings and conditions should be distinct
    assert_not_equal(f.questionings[1], f2.questionings[1])
    assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)

    # new condition should point to new questioning
    assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])
  end

  test "replicating a standard form with a condition referencing an option should produce correct new option reference" do
    f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => true)

    # create condition with option reference
    f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'eq',
      :option => f.questions[0].option_set.options[0])

    # replicate and test
    f2 = f.replicate(:mode => :to_mission, :mission => get_mission)

    # questionings, conditions, and options should be distinct
    assert_not_equal(f.questionings[1], f2.questionings[1])
    assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)
    assert_not_equal(f.questionings[0].question.option_set.optionings[0].option, f2.questionings[0].question.option_set.optionings[0].option)

    # new condition should point to new questioning
    assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])

    # new condition should point to new option
    assert_not_nil(f2.questionings[1].condition.option)
    assert_not_nil(f2.questionings[0].question.option_set.optionings[0].option)
    assert_equal(f2.questionings[1].condition.option, f2.questionings[0].question.option_set.optionings[0].option)
  end

  test "replicating a form with multiple conditions should also work" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer integer))

    # create conditions
    f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1)
    f.questionings[3].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[1], :op => 'gt', :value => 1)

    f2 = f.replicate(:mode => :clone)
    # new conditions should point to new questionings
    assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])
    assert_equal(f2.questionings[3].condition.ref_qing, f2.questionings[1])
  end

  test "adding new question with condition to middle of form should add to copy also" do
    # setup
    f = FactoryGirl.create(:form, :question_types => %w(integer integer), :is_standard => true)
    f2 = f.replicate(:mode => :to_mission, :mission => get_mission)

    # add question to std
    f.questionings.build(:rank => 2, :question => FactoryGirl.create(:question, :code => 'charley', :is_standard => true),
      :condition => Condition.new(:ref_qing => f.questionings[0], :op => 'gt', :value => '1', :is_standard => true))
    f.questionings[1].rank = 3
    f.save!

    # ensure question and condition got added properly on std
    f.reload
    assert_equal('charley', f.questionings[1].question.code)
    assert_equal(f.questionings[0], f.questionings[1].condition.ref_qing)

    # ensure replication was ok
    f2.reload
    assert_equal('charley', f2.questionings[1].question.code)
    assert_equal(f2.questionings[0], f2.questionings[1].condition.ref_qing)
    assert_not_equal(f.questionings[1].question.id, f2.questionings[1].question.id)
  end

  test "adding new condition to std form should create copy" do
    # setup
    f = FactoryGirl.create(:form, :question_types => %w(integer integer), :is_standard => true)
    f2 = f.replicate(:mode => :to_mission, :mission => get_mission)

    # add condition to standard
    f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'lt', :value => 10)
    f.save!

    f2.reload

    # a similiar condition should now exist in copy
    assert_equal("10", f2.questionings[1].condition.value)
    assert_equal(get_mission, f2.questionings[1].condition.mission)
    assert_equal(f2.questionings[0], f2.questionings[1].condition.ref_qing)

    # but conditions should be distinct
    assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)
  end

  test "changing condition ref_qing should replicate properly" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer), :is_standard => true)

    # create condition
    f.questionings[2].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1, :is_standard => true)
    f.save!

    # replicate first time
    f2 = f.replicate(:mode => :to_mission, :mission => get_mission)

    # change condition ref_qing
    f.questionings[2].condition.ref_qing = f.questionings[1]
    f.save!

    # ensure change replicated
    f2.reload
    assert_equal(f2.questionings[1], f2.questionings[2].condition.ref_qing)
  end

  test "changes replicated to multiple copies" do
    std = FactoryGirl.create(:form, :question_types => %w(integer integer integer), :is_standard => true)
    c1 = std.replicate(:mode => :to_mission, :mission => get_mission)
    c2 = std.replicate(:mode => :to_mission, :mission => FactoryGirl.create(:mission, :name => 'foo'))

    # add option set to first question
    q = std.questions[0]
    q.qtype_name = 'select_one'
    q.option_set = FactoryGirl.create(:option_set, :is_standard => true)
    q.save!

    # ensure change worked on std
    std.reload
    assert_equal('select_one', std.questions[0].qtype_name)

    # ensure two copies get made
    c1.reload
    c2.reload
    assert_equal('select_one', c1.questions[0].qtype_name)
    assert_equal('select_one', c2.questions[0].qtype_name)
  end

  test "question order should remain correct after replication" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer integer), :is_standard => true)
    copy = f.replicate(:mode => :to_mission, :mission => get_mission)

    first_std_q_id = f.questions[0].id
    first_copy_q_id = copy.questions[0].id

    # change the first question in std
    q = f.questions[0]
    q.qtype_name = "decimal"
    q.save!

    # ensure question order is still correct
    f.reload
    assert_equal(first_std_q_id, f.questions[0].id)
    copy.reload
    assert_equal(first_copy_q_id, copy.questions[0].id)
  end

  test "removal of question should be replcated to copy" do
    std = FactoryGirl.create(:form, :question_types => %w(integer decimal date), :is_standard => true)
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # use the special destroy_questionings method
    std.destroy_questionings(std.questionings[1])
    std.save

    copy.reload
    assert_equal(2, copy.questionings.size)
    assert_equal(2, copy.questions.size)
    assert_equal(%w(integer date), copy.questionings.map(&:qtype_name))

    # ranks should also remain correct on copy
    assert_equal([1,2], copy.questionings.map(&:rank))
  end

  test "removal of condition from question should be replcated to copy" do
    std = FactoryGirl.create(:form, :question_types => %w(integer integer integer), :is_standard => true)

    # create condition
    std.questionings[2].condition = FactoryGirl.build(:condition, :ref_qing => std.questionings[0], :op => 'gt', :value => 1, :is_standard => true)
    std.save!
    std.reload

    # replicate initially
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # save copy condition id
    copy_cond_id = std.questionings[2].condition.id
    assert_not_nil(copy_cond_id)

    # remove condition and save the qing. this is how it will happen in the controller.
    std.questionings[2].destroy_condition
    assert_nil(std.questionings[2].condition)
    std.questionings[2].save!

    copy.reload

    # copy qing should still be linked to std
    assert_equal(std.questionings[2], copy.questionings[2].standard)

    # but questioning should have no condition and copied condition should no longer exist
    assert_nil(copy.questionings[2].condition)
    assert_nil(Condition.where(:id => copy_cond_id).first)
  end

  test "deleting a standard form should delete copies and copy questionings and conditions" do
    std = FactoryGirl.create(:form, :question_types => %w(integer integer), :is_standard => true)
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # add condition to standard, which will get replicated
    std.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => std.questionings[0], :op => 'lt', :value => 10)
    std.save!
    assert_not_nil(Questioning.where(:form_id => copy.id).first)

    # get ID of copy condition
    copy.reload
    copy_cond_id = copy.questionings[1].condition.id
    assert_not_nil(copy_cond_id)

    # destroy std
    std.destroy

    # copy and assoc'd questionings and conditions should be gone
    assert(!Form.exists?(copy))
    assert_nil(Questioning.where(:form_id => copy.id).first)
    assert_nil(Condition.where(:id => copy_cond_id).first)
  end
end
