require './test/test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase
  
  setup do
    prep_objects
  end
    
  test "duplicates testing" do
    
    # create a form
    create_form(:name => "form1")
    
    # create option set for question
    create_opt_set(%w(Yes No Maybe))
    
    # create question with selectable answer
    create_question(:code => "ee", :type => "select_one")
    
    # create question with integer answer
    # create_question(:code => "int ", :type => "integer")
    
    # create a response using question
    first_response = create_response(:form => @forms[:form1], :answers => { :ee => "Yes" })
    
    # create a duplicate response
    duplicate_response = create_response(:form => @forms[:form1], :answers => { :ee => "Yes" })
    
    # create a different response
    different_response = create_response(:form => @forms[:form1], :answers => { :ee => "Maybe" })
    
    # assert the two duplicate response signatures are equal
    assert_equal(first_response.signature,duplicate_response.signature)
    
    # assert the different response signature is not equal to the first response signature
    assert_not_equal(different_response.signature,first_response.signature)
    
  end


end 
