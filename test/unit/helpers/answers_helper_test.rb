require 'test_helper'

class AnswersHelperTest < ActionView::TestCase

  test 'format_answer returns correct float value' do
    f = FactoryGirl.create(:form, :question_types => %w(decimal))
    a = FactoryGirl.create(:answer, :value => '123.28397928347392', :questioning => f.questionings[0])
    assert_equal('123.28', format_answer(a, :table_cell))
  end

  test 'format_answer returns correct datetime value' do
    f = FactoryGirl.create(:form, :question_types => %w(datetime))
    a = FactoryGirl.create(:answer, :datetime_value => '2012-01-01 12:34', :questioning => f.questionings[0])
    assert_equal('Jan 01 2012 12:34', format_answer(a, :table_cell))
  end

  test 'format_answer returns blank for nil datetime value' do
    f = FactoryGirl.create(:form, :question_types => %w(datetime))
    a = FactoryGirl.create(:answer, :datetime_value => nil, :questioning => f.questionings[0])
    assert_equal('', format_answer(a, :table_cell))
  end

end
