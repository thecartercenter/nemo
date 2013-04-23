require './test/test_helper'

class Response::DuplicatesTest < ActiveSupport::TestCase
  
  setup do
    prep_objects
  end
    
  test "duplicates testing" do

    # create a form
    form1 = create_form(:name => "form1")
    
    # create option set for question
    create_opt_set(%w(Yes No Maybe))
    
    # create question with selectable answer
    puts("created form " + @forms[:form1].id.to_s )
    create_question(:code => "ee", :type => "select_one", :option_set => @option_sets[:Yes_No_Maybe], :forms => [form1] )
    
    # create question with integer answer
    # create_question(:code => "int ", :type => "integer")

    # create a response using question
    first_response = create_response(:form => form1, :answers => { :ee => "Yes" })
    
    # create a duplicate response
    duplicate_response = create_response(:form => form1, :answers => { :ee => "Yes" })
    
    # create a different response
    different_response = create_response(:form => form1, :answers => { :ee => "Maybe" })
    
    # assert the two duplicate response signatures are equal
    assert_equal(first_response.signature,duplicate_response.signature)
    
    # assert the different response signature is not equal to the first response signature
    
    puts(" ID 1 " + different_response.id.to_s + " ID 2 " + duplicate_response.id.to_s)
    assert_not_equal(Response.find_by_id(different_response.id).signature,Response.find_by_id(duplicate_response.id).signature)
    
  end


end 
