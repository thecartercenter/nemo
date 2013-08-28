require 'test_helper'

class QuestioningTest < ActiveSupport::TestCase
  
  setup do
    clear_objects(Question, Questioning, Form)
  end
  
  test "creation" do
    # creating a protoform with a question should automatically create a questioning
    f = FactoryGirl.create(:form, :question_types => %w(integer))
    assert_equal(Questioning, f.questionings[0].class)
  end
  
  test "set rank" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal))
    assert_equal(1, f.questionings[0].rank)
    assert_equal(2, f.questionings[1].rank)
  end
  
  test "validates conditon" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal))
    assert_raise(ActiveRecord::RecordNotSaved) do
      # not sure why this is raising an exception but no time to find out
      f.questionings.last.condition = Condition.new(:ref_qing => f.questionings.first, :op => nil)
    end
  end
  
  test "previous" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal integer))
    assert_equal(f.questionings[0..1], f.questionings.last.previous)
  end

  test "duplicate" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal))
    
    # add condition to one questioning so we can test that
    f.questionings.last.condition = FactoryGirl.build(:condition, :ref_qing => f.questionings.first)
    f.questionings.last.save

    newqs = Questioning.duplicate(f.questionings)
    newqs.each_with_index do |newq, i|
      assert_not_equal(newq.id, f.questionings[i].id)
      %w(question_id rank required hidden).each do |a|
        assert_equal(newq[a], f.questionings[i][a])
      end
    end
    
    # try to add the questionings to a new form and save
    f2 = FactoryGirl.create(:form, :questionings => newqs)
    f2.save!
    
    # test that condition got duped and saves properly
    assert_not_equal(newqs.last.condition, f.questionings.last.condition)
    assert_not_nil(newqs.last.condition.id)
  end

  test "replicating questioning should replicate question" do

  end
  
end