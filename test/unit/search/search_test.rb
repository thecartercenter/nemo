require 'test_helper'

class Search::SearchTest < ActiveSupport::TestCase

  TYPICAL = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1", :default => true),

    # this is just a regular-type qualifier that is not the default
    Search::Qualifier.new(:name => "source", :col => "t.source"),

    # this qualifier allows partial matches but is not indexed with sphinx
    Search::Qualifier.new(:name => "submitter", :col => "t3.f3", :type => :text),

    # this qualifier supports scale-type comparison operators
    Search::Qualifier.new(:name => "submit_date", :col => "t.subdate", :type => :scale)
  ]

  NO_DEFAULTS = [
    Search::Qualifier.new(:name => "form", :col => "t1.f1")
  ]

  MULTIPLE_DEFAULTS = [
    Search::Qualifier.new(:name => "foo", :col => "t1.f1"),
    Search::Qualifier.new(:name => "bar", :col => "t1.f2", :default => true),
    Search::Qualifier.new(:name => "baz", :col => "t1.f3", :default => true)
  ]

  REGEX = [
    Search::Qualifier.new(:name => "foo1", :pattern => /^[a-n]+$/, :col => "t1.f1"),
    Search::Qualifier.new(:name => "name", :col => "t1.f2"),
    Search::Qualifier.new(:name => "foo2", :pattern => /^\{([a-z]+)\}$/, :col => "t1.f3"),
    Search::Qualifier.new(:name => "foo3", :pattern => /^~([a-z]+)~$/, :col => "t1.f3"),
    Search::Qualifier.new(:name => "foo4", :pattern => /^z([0-9]+)$/, :col => "t9.f7", :validator => ->(md){ md[1].size < 4 })
  ]

  INDEXED = [
    Search::Qualifier.new(:name => "text", :col => "tbl.id", :type => :indexed),
    Search::Qualifier.new(:name => "source", :col => "t.source")
  ]

  test "no defaults" do
    assert_search(:str => "v", :error => /must use a qualifier/, :qualifiers => NO_DEFAULTS)
  end

  test "basic" do
    assert_search(:str => "v", :sql => "((t1.f1 = 'v'))")
  end

  test "boolean AND should be ignored" do
    assert_search(:str => "v1 | and", :sql => "((t1.f1 = 'v1') OR (t1.f1 = 'and'))")
  end

  test 'invalid qualifier should be handled gracefully' do
    assert_search(:str => 'foo:bar', :error => /'foo' is not a valid search qualifier/)
  end

  test 'qualifier with no text should be handled gracefully' do
    assert_search(:str => 'foo:', :error => /could not be understood due to unexpected text near the end/)
  end

  test 'qualifier with no text followed by proper qualifier should be handled gracefully' do
    assert_search(:str => 'foo: form:blah', :error => /could not be understood due to unexpected text near ':blah'/)
  end

  test "unqualified or should work" do
    assert_search(:str => "v1 | v2", :sql => "((t1.f1 = 'v1') OR (t1.f1 = 'v2'))")
  end

  test "multiple ors should work" do
    assert_search(:str => "v1 | v2 OR v3", :sql => "((t1.f1 = 'v1') OR (t1.f1 = 'v2') OR (t1.f1 = 'v3'))")
  end

  test "ors should work with second qualified expression" do
    assert_search(:str => "v1 | v2 OR v3 source: bar", :sql => "((t1.f1 = 'v1') OR (t1.f1 = 'v2') OR (t1.f1 = 'v3')) AND ((t.source = 'bar'))")
  end

  test "unqualified quoted string should match exact phrase" do
    assert_search(:str => '"foo bar baz"', :sql => "((t1.f1 = 'foo bar baz'))")
  end

  test "basic qualified search should work" do
    assert_search(:str => "source: v1", :sql => "((t.source = 'v1'))")
  end

  test "equal sign should work same as colon" do
    assert_search(:str => "source = v1", :sql => "((t.source = 'v1'))")
  end

  test "equal sign with extra term should work" do
    assert_search(:str => "source = v1 v2", :sql => "((t.source = 'v1')) AND ((t1.f1 = 'v2'))")
  end

  test "AND should not be allowed for regular default qualifiers" do
    assert_search(:str => "v1 v2", :error => /Multiple terms aren't allowed for 'form' searches/)
  end

  test "AND should not be allowed for regular qualifiers" do
    assert_search(:str => "source: (v1 v2)", :error => /Multiple terms aren't allowed for 'source' searches/)
  end

  test "parentheses shouldnt be allowed in unqualified terms" do
    assert_search(:str => "v1 (v2 | v3)", :error => /unexpected text near '\(v2 \| v3\)'/)
  end

  test "nested parentheses shouldnt be allowed in qualified terms" do
    assert_search(:str => "foo: (v1 v2 (v3))", :error => /unexpected text near '\(v3\)\)'/)
  end

  test "ORs should work with qualified expression" do
    assert_search(:str => "source: (v1 | v2 OR v3)", :sql => "((t.source = 'v1') OR (t.source = 'v2') OR (t.source = 'v3'))")
  end

  test "OR should not be allowed between expressions" do
    assert_search(:str => "source: (v1 | v2) OR form: v3", :error => /OR is not allowed between expressions/)
  end

  test "quoted string should work with regular qualifier" do
    assert_search(:str => 'source: "v1 v2"', :sql => "((t.source = 'v1 v2'))")
  end

  test "not-equals operator should work for regular qualifiers" do
    assert_search(:str => "source != v1", :sql => "((t.source != 'v1'))")
  end

  test "gt operator should not work for regular qualifiers" do
    assert_search(:str => "form > v1", :error => /The operator '>' is not valid for the qualifier 'form'/)
  end

  test "blank should work for regular qualifiers" do
    assert_search(:str => "source: [blank]", :sql => "((t.source IS NULL))")
  end

  test "non-blank should work for regular qualifiers" do
    assert_search(:str => "form != [blank]", :sql => "((t1.f1 IS NOT NULL))")
  end

  test "blank should work in other language" do
    I18n.locale = :fr
    assert_search(:str => "source: [vide]", :sql => "((t.source IS NULL))")
    I18n.locale = :en
  end

  test "gt operator should work with scale-type qualifier" do
    assert_search(:str => "submit-date > 5", :sql => "((t.subdate > '5'))")
  end

  test "second number should not get taken into gt operator expression" do
    assert_search(:str => "submit-date > 5 6", :sql => "((t.subdate > '5')) AND ((t1.f1 = '6'))")
  end

  test "AND should not be allowed for scale qualifiers" do
    assert_search(:str => "submit-date > (5 6)", :error => /Multiple terms aren't allowed for 'submit-date' searches unless OR is used./)
  end

  test "scale qualifier should work with regular qualifier" do
    assert_search(:str => "submit-date <= 5 source: bar", :sql => "((t.subdate <= '5')) AND ((t.source = 'bar'))")
  end

  test "text qualifier should work" do
    assert_search(:str => "submitter: (v1 v2) source: bar", :sql => "((t3.f3 LIKE '%v1%') AND (t3.f3 LIKE '%v2%')) AND ((t.source = 'bar'))")
  end

  test "text qualifier with quoted string should work" do
    assert_search(:str => "submitter: (v1 \"v2 v3\") source: bar", :sql => "((t3.f3 LIKE '%v1%') AND (t3.f3 LIKE '%v2 v3%')) AND ((t.source = 'bar'))")
    assert_search(:str => 'submitter: "v1 v2" source: bar', :sql => "((t3.f3 LIKE '%v1 v2%')) AND ((t.source = 'bar'))")
  end

  test "text qualifier with OR should work" do
    assert_search(:str => "submitter: (v1 | v2) source: bar", :sql => "((t3.f3 LIKE '%v1%') OR (t3.f3 LIKE '%v2%')) AND ((t.source = 'bar'))")
  end

  test "text qualifier with AND and OR should work" do
    assert_search(:str => "submitter: (v1 v2 | v3) source: bar",
      :sql => "((t3.f3 LIKE '%v1%') AND (t3.f3 LIKE '%v2%') OR (t3.f3 LIKE '%v3%')) AND ((t.source = 'bar'))")
  end

  test "gt operator shouldnt be allowed for text qualifier" do
    assert_search(:str => "submitter > v1", :error => /The operator '>' is not valid for the qualifier 'submitter'/)
  end

  test "not equals operator should work with text qualifier" do
    assert_search(:str => "submitter != v1", :sql => "((t3.f3 NOT LIKE '%v1%'))")
  end

  test "quoted string with quoted string inside should still work" do
    assert_search(:str => 'submitter:"v1 \\"v2 v3\\" v4"', :sql => %{((t3.f3 LIKE '%v1 \\"v2 v3\\" v4%'))})
  end

  test "indexed qualifiers should work" do
    assert_search(:str => 'text:alpha source:bar', :sql => "((tbl.id IN (###0###))) AND ((t.source = 'bar'))", :qualifiers => INDEXED)
  end

  test "indexed qualifiers should work with multiple terms" do
    assert_search(:str => 'source:bar text:(alpha bravo)', :sql => "((t.source = 'bar')) AND ((tbl.id IN (###1###)))", :qualifiers => INDEXED)
    assert_equal('alpha bravo', @search.expressions.detect{|e| e.qualifier.name == 'text'}.values)
  end

  test "indexed qualifiers should work with exact phrases" do
    assert_search(:str => 'text:"alpha bravo"', :sql => "((tbl.id IN (###0###)))", :qualifiers => INDEXED)
    assert_equal('"alpha bravo"', @search.expressions.detect{|e| e.qualifier.name == 'text'}.values)
  end

  test "indexed qualifiers should work with OR operator" do
    assert_search(:str => 'text:(alpha OR bravo)', :sql => "((tbl.id IN (###0###)))", :qualifiers => INDEXED)
    assert_equal('alpha | bravo', @search.expressions.detect{|e| e.qualifier.name == 'text'}.values)
  end

  test "indexed qualifiers should work with minus operator" do
    assert_search(:str => 'text:(alpha -bravo)', :sql => "((tbl.id IN (###0###)))", :qualifiers => INDEXED)
    assert_equal('alpha -bravo', @search.expressions.detect{|e| e.qualifier.name == 'text'}.values)
  end

  test "indexed qualifiers should not allow not equals operator" do
    assert_search(:str => 'text != alpha', :error => /The operator '!=' is not valid for the qualifier 'text'/, :qualifiers => INDEXED)
  end

  test "odd characters in terms should still work" do
    assert_search(:str => "v1-_+'^&", :sql => "((t1.f1 = 'v1-_+\\'^&'))")
  end

  test "blank search should work" do
    assert_search(:str => "  ", :sql => "1")
    assert_search(:str => nil, :sql => "1")
  end

  test "regex qualifier should match correctly" do
    assert_search(:str => "anel:foo", :sql => "((t1.f1 = 'foo'))", :qualifiers => REGEX)
    assert_search(:str => "{abdb}:foo", :sql => "((t1.f3 = 'foo'))", :qualifiers => REGEX)
    assert_equal("{abdb}", @search.expressions.first.qualifier_text)
    assert_search(:str => "{a}:foo", :sql => "((t1.f3 = 'foo'))", :qualifiers => REGEX)
    assert_search(:str => "{abd8b}:foo", :error => /'{abd8b}' is not a valid search qualifier/, :qualifiers => REGEX)
    assert_search(:str => "x:foo", :error => /'x' is not a valid search qualifier/, :qualifiers => REGEX)
  end

  test "non regex qualifier should take precedence" do
    assert_search(:str => "name:foo", :sql => "((t1.f2 = 'foo'))", :qualifiers => REGEX)
  end

  test "qualifier validation lambda should work" do
    # z followed by 3 or less digits should work, more digits should not
    assert_search(:str => "z123:foo", :sql => "((t9.f7 = 'foo'))", :qualifiers => REGEX)
    assert_search(:str => "z12345:foo", :error => /not a valid search qualifier/, :qualifiers => REGEX)
  end

  test "search with multiple default qualifiers should work" do
    assert_search(:str => 'test', :sql => "((t1.f2 = 'test') OR (t1.f3 = 'test'))", :qualifiers => MULTIPLE_DEFAULTS)
  end

  private
    # special assertion to test search parsing
    # params:
    #  :str - the search string
    #  :klass - the dummy class from which the search_qualifiers should be pulled
    #  :sql - the expected sql
    #  :error - a regexp to match against the raised error's message. if no error raised, fail.
    def assert_search(params)
      params[:qualifiers] ||= TYPICAL
      error_msg = nil
      begin
        @search = Search::Search.new(:str => params[:str], :qualifiers => params[:qualifiers])
      rescue
        if params[:error]
          error_msg = $!.to_s
        else
          raise $!
        end
      end

      if params[:error]
        if error_msg.nil?
          fail("No error raised")
        else
          assert_match(params[:error], error_msg)
        end
      else
        assert_equal(params[:sql], @search.sql)
      end
    end
end
