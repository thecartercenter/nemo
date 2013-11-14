# tests the search functionality for the response model
require 'test_helper'

class Search::ResponseSearchTest < ActiveSupport::TestCase

  setup do
    # setup a basic form
    @form = FactoryGirl.create(:form, :name => 'foo', :question_types => %w(integer))
  end

  test "form qualifier should work" do
    # setup a second form
    @form2 = FactoryGirl.create(:form, :name => 'bar', :question_types => %w(integer))

    # create responses
    r1 = FactoryGirl.create(:response, :form => @form)
    r2 = FactoryGirl.create(:response, :form => @form2)
    r3 = FactoryGirl.create(:response, :form => @form)

    assert_search_matches('form:foo', r1, r3)
  end

  # TODO test other qualifiers

  test "answers qualifier should work with long_text questions" do
    # add long text question
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')

    # add some responses
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'the quick brown'])
    r2 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'fox jumps'])
    r3 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'over the lazy brown dog'])

    assert_search_matches('text:brown', r1, r3)
  end

  test "answers qualifier should match short text questions and multiple questions" do
    # add long text and short text question
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'text')

    # add some responses
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'the quick brown', 'alpha'])
    r2 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'fox jumps', 'bravo'])
    r3 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'over bravo the lazy dog', 'charlie'])

    assert_search_matches('text:bravo', r2, r3)
  end

  test "answers qualifier should be the default" do
    # add long text question
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')

    # add some responses
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'the quick brown'])
    r2 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'fox jumps'])

    assert_search_matches('brown', r1)
  end

  test "exact phrase matching should work" do
    # add long text question
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')

    # add some responses
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'the quick brown'])
    r2 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'the brown quick'])
    
    assert_search_matches(%{text:(quick brown)}, r1, r2) # parenths don't force exact phrase matching
    assert_search_matches(%{text:"quick brown"}, r1)
    assert_search_matches(%{"quick brown"}, r1)
    assert_search_matches(%{quick brown}, r1, r2)
    assert_search_matches(%{(quick brown)}, r1, r2)
  end

  test "question codes should work as qualifiers" do
    # add two long text questions with explicit codes
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'blue')
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'green')

    # add some responses
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'alpha bravo charlie', 'delta echo'])
    r2 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'foxtrot golf', 'alpha hotel india'])
    r3 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'juliet lima', 'mike november'])

    # search regularly
    assert_search_matches('text:alpha', r1, r2)
    
    # search by code
    assert_search_matches('{blue}:alpha', r1)
    assert_search_matches('{green}:alpha', r2)
  end

  test "invalid question codes should raise error" do
    assert_raise(Search::ParseError) do
      assert_search_matches('{foo}:bar')
    end
  end

  test "using code from other mission should raise error" do
    # create other mission and question
    other_mission = FactoryGirl.create(:mission, :name => 'other')
    FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'blue', :mission => other_mission)

    assert_raise(Search::ParseError) do
      assert_search_matches('{blue}:bar')
    end

    # now create in the default mission and try again
    FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'blue')
    assert_search_matches('{blue}:bar') # should match nothing, but not error
  end

  test "response should only appear once even if it has two matching answers" do
    # add two long text questions
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')
    @form.questions << FactoryGirl.create(:question, :qtype_name => 'long_text')

    # add a response with same word in both answers
    r1 = FactoryGirl.create(:response, :form => @form, :_answers => [1, 'alpha bravo charlie', 'delta bravo'])

    # make sure only matches once
    assert_search_matches('text:bravo', r1)    
  end
  
  private
    def assert_search_matches(query, *objs)
      @search = Search::Search.new(:str => query)
      @search.qualifiers = Response.search_qualifiers(:mission => get_mission)
      results = @search.apply(Response.unscoped).all
      assert_equal(objs, results)
    end
end