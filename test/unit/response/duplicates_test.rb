require 'test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase

  setup do

    prep_objects

    @form1 = FactoryGirl.create(:form)
    user

    # create option set for question
    @opt_set = FactoryGirl.create(:option_set, :option_names => %w(Yes No Maybe))

    # create question with selectable answer
    @question_sel1 = FactoryGirl.create(:question, :code => "q1", :forms => [@form1], :qtype_name => "select_one", :option_set => @opt_set)

    # create another question
    @question_sel2 = FactoryGirl.create(:question, :code => "q2", :forms => [@form1], :qtype_name => "select_one", :option_set => @opt_set)

    # create question with value as answer
    @question_val = FactoryGirl.create(:question, :code => "q3", :forms => [@form1], :qtype_name => "text")

    # create question that takes multiple selections
    @question_sel_multi = FactoryGirl.create(:question, :code => "q4", :forms => [@form1], :qtype_name => "select_multiple", :option_set => @opt_set)

  end

  test "two identical responses" do

    # create a response using question
    response1 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value", :q4 => ["Yes","No"]})

    # create a duplicate response
    response1_copy = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value", :q4 => ["Yes","No"]})

    # assert the two duplicate response signatures are equal
    assert_equal(response1.signature,response1_copy.signature)

  end

  test "responses using choices for answers" do

    # create a different response with a different value for value question
    response1 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" , :q4 => ["Yes","No"]})

    # create a response with a different options for select_multiple question
    response2 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" , :q4 => ["No","No"]})

    # assert response1 has a different signature than the response with different multiple options selected
    assert_not_equal(response1.signature,response2.signature)

  end

  test "responses using text values for answers" do

    # create a different response with a different value for value question
    response1 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" , :q4 => ["Yes","No"]})

    # response with different value for text value
    response2 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "different value" , :q4 => ["Yes","No"]})

    assert_not_equal(response1.signature,response2.signature)
  end

  test "empty responses" do
    # create a response using question
    response1 = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value", :q4 => ["Yes","No"]})

    empty_response = FactoryGirl.create(:response_for_duplicate_testing, :form => @form1, :answer_names => {})

    # test whether response was created with no answers submitted
    assert_not_nil(empty_response.signature,"Empty Response's signature not nil")

    # assert the empty response's signature is not equal to the first response's signature
    assert_not_equal(empty_response.signature,response1.signature)

  end

end
