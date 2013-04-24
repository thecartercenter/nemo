require './test/test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase
  
  setup do
    prep_objects
  end
    
  test "duplicates testing" do
    
    form1 = create_form(:name => "form1")
        
    # create option set for question
    create_opt_set(%w(Yes No Maybe))
    
    # create question with selectable answer
    create_question(:forms => [form1], :code => "ee", :type => "select_one", :option_set => @option_sets[:Yes_No_Maybe])
    
    # create another question
    create_question(:forms => [form1], :code => "fb", :type => "select_one", :option_set => @option_sets[:Yes_No_Maybe])
    
    # create question with value as answer  
    create_question(:forms => [form1], :code => "val", :type => "text")
      

    # create a response using question
    first_response = create_response(:form => form1, :answers => { :ee => "Yes", :fb => "Yes", :val => "value" })
    
    # create a duplicate response
    duplicate_response = create_response(:form => form1, :answers => { :ee => "Yes", :fb => "Yes", :val => "value" })
    
    # create a different response
    different_response = create_response(:form => form1, :answers => { :ee => "Yes", :fb => "No", :val => "value" })
    
    # create a response with a user input value
    value_response = create_response(:answers => { :val => "tits" })
    
    
    # assert the two duplicate response signatures are equal
    assert_equal(first_response.signature,duplicate_response.signature)
    
    # assert the different response signature is not equal to the first response signature
    assert_not_equal(different_response.signature,duplicate_response.signature)
    
    assert_not_equal(different_response.signature,value_response.signature)
    
    
  end


end 
