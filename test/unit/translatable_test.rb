require 'test_helper'

class TranslatableTest < ActiveSupport::TestCase

  test "translatable" do
    q = Question.new

    I18n.locale = :en

    assert_equal(nil, q.name)
    assert_equal(nil, q.name_en)
    assert_equal(nil, q.name(:fr))

    q.name_en = "foo"

    assert_equal("foo", q.name)
    assert_equal("foo", q.name_en)
    assert_equal(nil, q.name(:fr))
    assert_equal("foo", q.name(:fr, :strict => false))
    assert_equal("foo", q.name("fr", :strict => false))
    assert_equal("foo", q.name_fr(:strict => false))

    q.name = "bar"

    assert_equal("bar", q.name)
    assert_equal("bar", q.name_en)
    assert_equal(nil, q.name(:fr))

    q.name_fr = "feu"

    assert_equal("feu", q.name(:fr))
    assert_equal("bar", q.name("en"))
    assert_equal("bar", q.name)

    q.hint = "baz"

    assert_equal("feu", q.name(:fr))
    assert_equal("bar", q.name("en"))
    assert_equal("baz", q.hint("en"))

    I18n.locale = :fr

    assert_equal("feu", q.name)

    q.name = "zing"

    assert_equal("zing", q.name)
    assert_equal("zing", q.name_fr)
    assert_equal("bar", q.name_en)

    I18n.locale = :en

    assert_equal("bar", q.name)
  end

  test "available locales" do
    q = Question.new
    I18n.locale = :en

    assert_equal([], q.available_locales)
    q.name_en = "foo"
    assert_equal([:en], q.available_locales)
    q.hint_fr = "foo"
    assert_equal([:en, :fr], q.available_locales)
    assert_equal([:fr], q.available_locales(:except_current => true))
  end

  test "all blank" do
    q = Question.new
    q.name_translations = nil
    assert_equal(true, q.name_all_blank?)
    q.name_en = ""
    assert_equal(true, q.name_all_blank?)
    q.name_en = "foo"
    assert_equal(false, q.name_all_blank?)
    q.name_fr = "bar"
    q.name_en = ""
    assert_equal(false, q.name_all_blank?)
    q.name_fr = ""
    assert_equal(true, q.name_all_blank?)
    q.name_fr = nil
    assert_equal(true, q.name_all_blank?)
  end

end
