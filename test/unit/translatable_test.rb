require 'test_helper'

class TranslatableTest < ActiveSupport::TestCase

  test "translatable" do
    o = ProtoOption.new
    
    I18n.locale = :en
    
    assert_equal(nil, o.name)
    assert_equal(nil, o.name_en)
    assert_equal(nil, o.name(:fr))
    
    o.name_en = "foo"

    assert_equal("foo", o.name)
    assert_equal("foo", o.name_en)
    assert_equal(nil, o.name(:fr))
    assert_equal("foo", o.name(:fr, :strict => false))
    assert_equal("foo", o.name("fr", :strict => false))
    assert_equal("foo", o.name_fr(:strict => false))
    
    o.name = "bar"
    
    assert_equal("bar", o.name)
    assert_equal("bar", o.name_en)
    assert_equal(nil, o.name(:fr))

    o.name_fr = "feu"
    
    assert_equal("feu", o.name(:fr))
    assert_equal("bar", o.name("en"))
    assert_equal("bar", o.name)
    
    o.hint = "baz"
    
    assert_equal("feu", o.name(:fr))
    assert_equal("bar", o.name("en"))
    assert_equal("baz", o.hint("en"))
    
    I18n.locale = :fr
    
    assert_equal("feu", o.name)
    
    o.name = "zing"
    
    assert_equal("zing", o.name)
    assert_equal("zing", o.name_fr)
    assert_equal("bar", o.name_en)
    
    I18n.locale = :en

    assert_equal("bar", o.name)
  end
  
  test "available locales" do
    o = ProtoOption.new
    I18n.locale = :en
    
    assert_equal([], o.available_locales)
    o.name_en = "foo"
    assert_equal([:en], o.available_locales)
    o.hint_fr = "foo"
    assert_equal([:en, :fr], o.available_locales)
    assert_equal([:fr], o.available_locales(:except_current => true))
  end
  
  test "delelgated translations" do
    o = Option.new
    o.proto_option = ProtoOption.new
    o.proto_option.name_en = 'blarb'
    assert_equal('blarb', o.name)
    o.name_en = 'chork'
    assert_equal('chork', o.name)
    assert_equal('chork', o.proto_option.name_en)
  end

  test "delelgated translation get with nil delegate" do
    o = Option.new
    assert_raise(ArgumentError){o.name}
  end

  test "delelgated translation set with nil delegate" do
    o = Option.new
    assert_raise(ArgumentError){o.name_en = 'foo'}
  end
  
  test "delegated available locales" do
    o = Option.new
    o.proto_option = ProtoOption.new
    o.proto_option.name_en = 'blarb'
    o.proto_option.name_fr = 'blarbz'
    assert_equal([:en, :fr], o.proto_option.available_locales)
    assert_equal([:en, :fr], o.available_locales)
  end
  
  test "delelgated available locales with nil delegate" do
    o = Option.new
    assert_raise(ArgumentError){o.available_locales}
  end
end
