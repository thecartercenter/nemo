require 'test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase
  
  setup do
    prep_objects
  end
    
  test "duplicates testing" do
    
    user
    
    form1 = FactoryGirl.create(:form)
        
    # create option set for question
    opt_set = FactoryGirl.create(:option_set, :option_names => %w(Yes No Maybe))
        
    # create question with selectable answer
    question1 = FactoryGirl.create(:question, :code => "q1", :forms => [form1], :qtype_name => "select_one", :option_set => opt_set)
    
    # create another question
    question2 = FactoryGirl.create(:question, :code => "q2", :forms => [form1], :qtype_name => "select_one", :option_set => opt_set)
    
    # create question with value as answer  
    question3 = FactoryGirl.create(:question, :code => "q3", :forms => [form1], :qtype_name => "text")

    # create a response using question
    response1 = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value"})

    # create a duplicate response
    response1_copy = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value" })

    # create a different response
    different_response = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" })

    # create empty response
    empty_response = FactoryGirl.create(:response, :form => form1, :answer_names => {})

    # create response with no signature
    response_no_sig = FactoryGirl.create(:response, :form => form1, :answer_names => {})
    response_no_sig.signature = nil

    # test whether response was created with no answers submitted
    assert_not_nil(empty_response,"Empty Response not nil")
    
    # assert the two duplicate response signatures are equal
    assert_equal(response1.signature,response1_copy.signature)
    
    # assert the different response signature is not equal to the first response signature
    assert_not_equal(empty_response.signature,response1.signature)
        
  end


end 
