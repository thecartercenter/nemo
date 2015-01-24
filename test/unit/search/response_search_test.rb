# tests the search functionality for the response model
require 'test_helper'
require 'sphinx_helper'

class Search::ResponseSearchTest < ActiveSupport::TestCase

  test "form qualifier should work" do
    setup_basic_form
    # setup a second form
    @form2 = FactoryGirl.create(:form, :name => 'bar', :question_types => %w(integer))

    # create responses
    r1 = FactoryGirl.create(:response, :form => @form)
    r2 = FactoryGirl.create(:response, :form => @form2)
    r3 = FactoryGirl.create(:response, :form => @form)

    assert_search('form:foo', r1, r3)
  end

  # this is all in one test because sphinx is costly to setup and teardown
  test "response full text searches should work" do
    # make sure sphinx is running, and responses have been added and indexed
    ThinkingSphinx::Test.init
    ThinkingSphinx::Test.run do
      no_transaction do

        setup_basic_form

        # add long text and short text question
        FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'mauve', :add_to_form => @form)
        FactoryGirl.create(:question, :qtype_name => 'text', :add_to_form => @form)

        # add two long text questions with explicit codes
        FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'blue', :add_to_form => @form)
        FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'Green', :add_to_form => @form)

        # add some responses
        r1 = FactoryGirl.create(:response, :form => @form, :reviewed => false,
          :answer_values => [1, 'the quick brown', 'alpha', 'apple bear cat', 'dog earwax ipswitch'])
        r2 = FactoryGirl.create(:response, :form => @form, :reviewed => true,
          :answer_values => [1, 'fox heaven jumps', 'bravo', 'fuzzy gusher', 'apple heaven ipswitch'])
        r3 = FactoryGirl.create(:response, :form => @form, :reviewed => true,
          :answer_values => [1, 'over bravo the lazy brown quick dog', 'contour', 'joker lumpy', 'meal nexttime'])

        do_sphinx_index

        # answers qualifier should work with long_text questions
        assert_search('text:brown', r1, r3)

        # answers qualifier should match short text questions and multiple questions
        assert_search('text:bravo', r2, r3)

        # answers qualifier should be the default
        assert_search('quick brown', r1, r3)

        # exact phrase matching should work
        assert_search(%{text:(quick brown)}, r1, r3) # parenths don't force exact phrase matching
        assert_search(%{text:"quick brown"}, r1)
        assert_search(%{"quick brown"}, r1)

        # question codes should work as qualifiers
        assert_search('text:apple', r1, r2)
        assert_search('{blue}:apple', r1)
        assert_search('{Green}:apple', r2)

        #invalid question codes should raise error
        assert_search('{foo}:bar', :error => /'{foo}' is not a valid search qualifier./)

        # using code from other mission should raise error
        # create other mission and question
        other_mission = FactoryGirl.create(:mission, :name => 'other')
        FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'purple', :mission => other_mission)
        assert_search('{purple}:bar', :error => /valid search qualifier/)
        # now create in the default mission and try again
        FactoryGirl.create(:question, :qtype_name => 'long_text', :code => 'purple')
        assert_search('{purple}:bar') # should match nothing, but not error

        # response should only appear once even if it has two matching answers
        assert_search('text:heaven', r2)

        # multiple indexed qualifiers should work
        assert_search('{blue}:lumpy {Green}:meal', r3)
        assert_search('{blue}:lumpy {Green}:ipswitch')

        # mixture of indexed and normal qualifiers should work
        assert_search('{Green}:ipswitch reviewed:1', r2)

        # excerpts should be correct
        assert_excerpts('text:heaven', [
          [{:questioning_id => @form.questionings[1].id, :code => 'mauve', :text => "fox {{{heaven}}} jumps"},
           {:questioning_id => @form.questionings[4].id, :code => 'Green', :text => "apple {{{heaven}}} ipswitch"}]
        ])
        assert_excerpts('{green}:heaven', [
          [{:questioning_id => @form.questionings[4].id, :code => 'Green', :text => "apple {{{heaven}}} ipswitch"}]
        ])
      end
    end
  end

  private

    def setup_basic_form
      @form = FactoryGirl.create(:form, :name => 'foo', :question_types => %w(integer))
    end

    def assert_search(query, *objs_or_error)
      if objs_or_error[0].is_a?(Hash)
        error_pattern = objs_or_error[0][:error]
        begin
          run_search(query)
        rescue
          assert_match(error_pattern, $!.to_s)
        else
          fail("No error was raised.")
        end
      else
        assert_equal(objs_or_error, run_search(query))
      end
    end

    # runs a search with the given query and checks the returned excerpts
    def assert_excerpts(query, excerpts)
      responses = run_search(query, :include_excerpts => true)
      assert_equal(excerpts.size, responses.size)
      responses.each_with_index{|r,i| assert_equal(excerpts[i], r.excerpts)}
    end

    def run_search(query, options = {})
      options[:include_excerpts] ||= false
      Response.do_search(Response.unscoped, query, {:mission => get_mission}, options)
    end
end