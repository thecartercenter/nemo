require 'test_helper'

class Search::SearchTest < ActiveSupport::TestCase

  TYPICAL = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1", :default => true),
    Search::Qualifier.new(:name => "name", :col => "t2.f2", :subst => {"yes" => "1", "no" => "0"}),
    Search::Qualifier.new(:name => "source", :col => "t3.f3", :partials => true),
    Search::Qualifier.new(:name => "answers", :col => "t4.f4", :fulltext => true)
  ]

  NO_DEFAULTS = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1")
  ]

  MULTIPLE_DEFAULTS = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1", :default => true),
    Search::Qualifier.new(:name => "name", :col => "t1.f2", :default => true)
  ]

  FULLTEXT_DEFAULT = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1", :default => true, :fulltext => true),
    Search::Qualifier.new(:name => "name", :col => "t1.f2")
  ]

  REGEX = [
    Search::Qualifier.new(:name => /^[a-n]+$/, :col => "t1.f1"),
    Search::Qualifier.new(:name => "name", :col => "t1.f2"),
    Search::Qualifier.new(:name => /^\{([a-z]+)\}$/, :col => "t1.f3"),
    Search::Qualifier.new(:name => /^~([a-z]+)~$/, :col => "t1.f3", :extra_condition => ->(md){ ["t2.f3 = ?", md[1]] }),
    Search::Qualifier.new(:name => /^z([0-9]+)$/, :col => "t9.f7", :validator => ->(md){ md[1].size < 4 })
  ]

  test "no defaults" do
    assert_raise(Search::ParseError){run_search(:qualifiers => NO_DEFAULTS, :str => "v")}
  end

  test "basic" do
    assert_search(:str => "v", :sql => "(t1.f1 = 'v')")
  end

  test "boolean" do 
    assert_search(:str => "v1 aNd v2", :sql => "(t1.f1 = 'v1') AND (t1.f1 = 'v2')")
  end
 
  test "odd characters in terms" do
    assert_search(:str => "v1-_+'^&", :sql => "(t1.f1 = 'v1-_+\\'^&')")
  end
  
  test "substitution" do
    assert_search(:str => "name:yes or (name:no and v1)", :sql => "(t2.f2 = '1') OR ((t2.f2 = '0') AND (t1.f1 = 'v1'))")
  end
  
  test "multiple defaults" do
    assert_search(:str => "v1 and v2", :sql => "(t1.f1 = 'v1' OR t1.f2 = 'v1') AND (t1.f1 = 'v2' OR t1.f2 = 'v2')", :qualifiers => MULTIPLE_DEFAULTS)
  end
  
  test "partials" do
    assert_search(:str => "source:v1 AND source!=v2", :sql => "(t3.f3 LIKE '%v1%') AND (t3.f3 NOT LIKE '%v2%')")
  end  
  
  test "blank" do
    assert_search(:str => "  ", :sql => "1")
    assert_search(:str => nil, :sql => "1")
  end

  test "parenths with qualifier should keep terms grouped" do
    assert_search(:str => "name:(foo bar baz)", :sql => "(t2.f2 = 'foo bar baz')")
    assert_search(:str => "name : ( foo bar baz )", :sql => "(t2.f2 = 'foo bar baz')")
  end

  test "multiple targets for qualifier should work" do
    assert_search(:str => "name:foo,bar,baz", :sql => "(t2.f2 = 'foo' OR t2.f2 = 'bar' OR t2.f2 = 'baz')")
    assert_search(:str => "name:foo, (bar baz), baz", :sql => "(t2.f2 = 'foo' OR t2.f2 = 'bar baz' OR t2.f2 = 'baz')")
  assert_search(:str => "name:foo, \"bar baz\", baz", :sql => "(t2.f2 = 'foo' OR t2.f2 = 'bar baz' OR t2.f2 = 'baz')")
  end

  test "quotes with regular qualifier should behave same as parenths" do
    assert_search(:str => "name:\"foo bar baz\"", :sql => "(t2.f2 = 'foo bar baz')")
  end

  test "parenths with fulltext qualifier should not match exact phrase" do
    assert_search(:str => "answers:(foo bar baz)", :sql => "(MATCH (t4.f4) AGAINST ('foo bar baz' IN BOOLEAN MODE))")
  end

  test "quotes with fulltext qualifier should match exact phrase" do
    assert_search(:str => "answers:\"foo bar baz\"", :sql => "(MATCH (t4.f4) AGAINST ('\\\"foo bar baz\\\"' IN BOOLEAN MODE))")
  end

  test "double quoted unqualified string should be handled correctly for non fulltext default qualifier" do
    assert_search(:str => "\"foo bar baz\"", :sql => "(t1.f1 = 'foo bar baz')")
  end

  test "double quoted unqualified string should be handled correctly for fulltext default qualifier" do
    assert_search(:str => "\"foo bar baz\"", :sql => "(MATCH (t1.f1) AGAINST ('\\\"foo bar baz\\\"' IN BOOLEAN MODE))", :qualifiers => FULLTEXT_DEFAULT)
  end

  test "unquoted unqualified string should be handled correctly for fulltext default qualifier" do
    assert_search(:str => "foo bar", :sql => "(MATCH (t1.f1) AGAINST ('foo' IN BOOLEAN MODE)) AND (MATCH (t1.f1) AGAINST ('bar' IN BOOLEAN MODE))", 
      :qualifiers => FULLTEXT_DEFAULT)
  end

  test "operators other than equal shouldnt be allowed with the fulltext qualifier" do
    assert_raise(Search::ParseError) do
      run_search(:str => "answers > foo")
    end
  end

  test "regex qualifier should match correctly" do
    assert_search(:str => "anel:foo", :sql => "(t1.f1 = 'foo')", :qualifiers => REGEX)
    assert_search(:str => "{abdb}:foo", :sql => "(t1.f3 = 'foo')", :qualifiers => REGEX)
    assert_search(:str => "{a}:foo", :sql => "(t1.f3 = 'foo')", :qualifiers => REGEX)
    assert_raise(Search::ParseError){run_search(:str => "{abd8b}:foo", :qualifiers => REGEX)}
    assert_raise(Search::ParseError){run_search(:str => "x:foo", :qualifiers => REGEX)}
  end

  test "non regex qualifier should take precedence" do
    assert_search(:str => "name:foo", :sql => "(t1.f2 = 'foo')", :qualifiers => REGEX)
  end

  test "extra_condition with match from regex qualifier should work" do
    assert_search(:str => "~abjf~ = foo", :sql => "((t1.f3 = 'foo') AND (t2.f3 = 'abjf'))", :qualifiers => REGEX)
  end

  test "qualifier validation lambda should work" do
    # z followed by 3 or less digits should work, more digits should not
    assert_search(:str => "z123:foo", :sql => "(t9.f7 = 'foo')", :qualifiers => REGEX)
    assert_raise(Search::ParseError){run_search(:str => "z12345:foo", :qualifiers => REGEX)}
  end

  private
    # special assertion to test search parsing
    # params: 
    #  :str - the search string
    #  :klass - the dummy class from which the search_qualifiers should be pulled
    #  :sql - the expected sql
    def assert_search(params)
     run_search(params)
     assert_equal(params[:sql], @search.sql)
    end
    
    def run_search(params)
     params[:qualifiers] ||= TYPICAL
     @search = Search::Search.new(:str => params[:str])
     @search.qualifiers = params[:qualifiers]
     @search.sql # ensure sql gets generated
    end
end
