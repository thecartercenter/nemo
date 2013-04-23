require './test/test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase
  
  setup do
    prep_objects
  end
    
  test "duplicates testing" do
    
    # create option set for question
    create_opt_set(%w(Yes No Maybe))
    
    # create question with selectable answer
    create_question(:code => "ee", :type => "select_one", :option_set => @option_sets[:Yes_No_Maybe])
    
    # create another question
    create_question(:code => "fb", :type => "select_one", :option_set => @option_sets[:Yes_No_Maybe])

    # create a response using question
    first_response = create_response(:answers => { :ee => "Yes", :fb => "Yes" })
    
    # create a duplicate response
    duplicate_response = create_response(:answers => { :ee => "Yes", :fb => "Yes" })
    
    # create a different response
    different_response = create_response(:answers => { :ee => "Maybe" })
    
    # assert the two duplicate response signatures are equal
    assert_equal(first_response.signature,duplicate_response.signature)
    
    # assert the different response signature is not equal to the first response signature
    assert_not_equal(different_response.signature,duplicate_response.signature)
    
  end


end 
