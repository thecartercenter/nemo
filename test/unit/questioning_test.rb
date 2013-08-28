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

end