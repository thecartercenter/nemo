require 'test_helper'

class TestTypical
  def self.search_qualifiers
    [
      Search::Qualifier.new(:label => "q1", :col => "t1.f1", :default => true),
      Search::Qualifier.new(:label => "q2", :col => "t2.f2", :subst => {"yes" => "1", "no" => "0"}),
      Search::Qualifier.new(:label => "q3", :col => "t3.f3", :partials => true)
    ]
  end
end

class TestNoDefaults
  def self.search_qualifiers
    [Search::Qualifier.new(:label => "q1", :col => "t1.f1")]
  end
end

class TestMultipleDefaults
  def self.search_qualifiers
    [
      Search::Qualifier.new(:label => "q1", :col => "t1.f1", :default => true),
      Search::Qualifier.new(:label => "q2", :col => "t1.f2", :default => true)
    ]
  end
end

class Search::SearchTest < ActiveSupport::TestCase
  test "no defaults" do
    assert_raise(Search::ParseError){run_search(:klass => TestNoDefaults, :str => "v")}
  end
  
  test "basic" do
    assert_search(:str => "v", :sql => "(t1.f1 = 'v')", :tables => %w(t1))
  end
  
  test "boolean" do 
    assert_search(:str => "v1 aNd v2", :sql => "(t1.f1 = 'v1') AND (t1.f1 = 'v2')", :tables => %w(t1))
  end
  
  test "odd characters in terms" do
    assert_search(:str => "v1-_+'^&", :sql => "(t1.f1 = 'v1-_+\\'^&')", :tables => %w(t1))
  end
  
  test "substitution" do
    assert_search(:str => "q2:yes or (q2:no and v1)", :sql => "(t2.f2 = '1') OR ((t2.f2 = '0') AND (t1.f1 = 'v1'))", :tables => %w(t1 t2))
  end
  
  test "multiple defaults" do
    assert_search(:str => "v1 and v2", :sql => "(t1.f1 = 'v1' OR t1.f2 = 'v1') AND (t1.f1 = 'v2' OR t1.f2 = 'v2')", 
      :tables => %w(t1), :klass => TestMultipleDefaults)
  end
  
  test "partials" do
    assert_search(:str => "q3:v1 AND q3!=v2", :sql => "(t3.f3 LIKE '%v1%') AND (t3.f3 NOT LIKE '%v2%')", :tables => %w(t3))
  end  
  
  test "blank" do
    assert_search(:str => "  ", :sql => "1", :tables => [])
    assert_search(:str => nil, :sql => "1", :tables => [])
  end
  
  # special assertion to test search parsing
  # params: 
  #  :str - the search string
  #  :klass - the dummy class from which the search_qualifiers should be pulled
  #  :sql - the expected sql
  #  :tables - the expected tables
  def assert_search(params)
    search = run_search(params)
    assert_equal(params[:sql], search.conditions)
    assert_equal(params[:tables].sort, search.tables.sort)
  end
  
  def run_search(params)
    params[:klass] ||= TestTypical
    search = Search::Search.new(:str => params[:str], :class_name => params[:klass].name)
    search.conditions
    search
  end
end
