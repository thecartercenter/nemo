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
    question_sel1 = FactoryGirl.create(:question, :code => "q1", :forms => [form1], :qtype_name => "select_one", :option_set => opt_set)
    
    # create another question
    question_sel2 = FactoryGirl.create(:question, :code => "q2", :forms => [form1], :qtype_name => "select_one", :option_set => opt_set)
    
    # create question with value as answer  
    question_val = FactoryGirl.create(:question, :code => "q3", :forms => [form1], :qtype_name => "text")

    # create question that takes multiple selections
    question_sel_multi = FactoryGirl.create(:question, :code => "q4", :forms => [form1], :qtype_name => "select_multiple", :option_set => opt_set)
    
    # create a response using question
    response1 = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value", :q4 => ["Yes","No"]})

    # create a duplicate response
    response1_copy = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "Yes", :q2 => "Yes", :q3 => "value", :q4 => ["Yes","No"]})

    # create a different response with a different value for value question
    different_value_response = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" , :q4 => ["Yes","No"]})
    
    # create a response with a different options for select_multiple question
    different_sel_multiple_response = FactoryGirl.create(:response, :form => form1, :answer_names => { :q1 => "No", :q2 => "Yes", :q3 => "value1" , :q4 => ["No","No"]})

    # create empty response
    empty_response = FactoryGirl.create(:response, :form => form1, :answer_names => {})

    # create response with no signature
    response_no_sig = FactoryGirl.create(:response, :form => form1, :answer_names => {})
    response_no_sig.signature = nil
    response_no_sig.duplicate = true
    
    # test whether response was created with no answers submitted
    assert_not_nil(empty_response,"Empty Response not nil")
    
    # assert the two duplicate response signatures are equal
    assert_equal(response1.signature,response1_copy.signature)
    
    # assert two different responses have different signatures
    assert_not_equal(response1.signature,different_value_response.signature)
    
    # assert the empty response's signature is not equal to the first response's signature
    assert_not_equal(empty_response.signature,response1.signature)     
    
    # assert response1 has a different signature than the response with different multiple options selected
    assert_not_equal(different_value_response.signature,different_sel_multiple_response.signature) 
    
    puts "different_value_response : " + different_value_response.signature.to_s
    puts "different sel mult response: " + different_sel_multiple_response.signature.to_s
    puts "response1_copy: " + response1_copy.signature.to_s
  end


end 
