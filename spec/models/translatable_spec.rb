require 'spec_helper'

class AClass
  include Translatable
  translates :name, :hint
  attr_accessor :canonical_name, :canonical_hint
end

describe 'Translatable' do

  it 'basic' do
    a = AClass.new

    I18n.locale = :en

    assert_equal(nil, a.name)
    assert_equal(nil, a.name_en)
    assert_equal(nil, a.name(:fr))

    a.name_en = "foo"

    assert_equal("foo", a.name)
    assert_equal("foo", a.name_en)
    assert_equal(nil, a.name(:fr))
    assert_equal("foo", a.name(:fr, :strict => false))
    assert_equal("foo", a.name("fr", :strict => false))
    assert_equal("foo", a.name_fr(:strict => false))

    a.name = "bar"

    assert_equal("bar", a.name)
    assert_equal("bar", a.name_en)
    assert_equal(nil, a.name(:fr))

    a.name_fr = "feu"

    assert_equal("feu", a.name(:fr))
    assert_equal("bar", a.name("en"))
    assert_equal("bar", a.name)

    a.hint = "baz"

    assert_equal("feu", a.name(:fr))
    assert_equal("bar", a.name("en"))
    assert_equal("baz", a.hint("en"))

    I18n.locale = :fr

    assert_equal("feu", a.name)

    a.name = "zing"

    assert_equal("zing", a.name)
    assert_equal("zing", a.name_fr)
    assert_equal("bar", a.name_en)

    I18n.locale = :en

    assert_equal("bar", a.name)
  end

  it 'available locales' do
    a = AClass.new
    I18n.locale = :en

    assert_equal([], a.available_locales)
    a.name_en = "foo"
    assert_equal([:en], a.available_locales)
    a.hint_fr = "foo"
    assert_equal([:en, :fr], a.available_locales)
    assert_equal([:fr], a.available_locales(:except_current => true))
  end

  it 'blanks' do
    a = AClass.new
    a.name_en = ''
    expect(a.name_en).to be_nil
    expect(a.name_translations).to be_nil

    a.name_fr = 'foo'
    a.name_en = ''
    expect(a.name_en).to be_nil
    expect(a.name_fr).to eq 'foo'
  end

  it 'all blank' do
    a = AClass.new
    a.name_translations = nil
    assert_equal(true, a.name_all_blank?)
    a.name_en = ""
    assert_equal(true, a.name_all_blank?)
    a.name_en = "foo"
    assert_equal(false, a.name_all_blank?)
    a.name_fr = "bar"
    a.name_en = ""
    assert_equal(false, a.name_all_blank?)
    a.name_fr = ""
    assert_equal(true, a.name_all_blank?)
    a.name_fr = nil
    assert_equal(true, a.name_all_blank?)
  end

  describe 'canonical name' do
    it 'should be default locale if available' do
      a = AClass.new
      a.name_en = 'Foo'
      expect(a.canonical_name).to eq 'Foo'
    end

    it 'should be first-entered locale if default not available' do
      a = AClass.new
      a.name_fr = 'Bar'
      expect(a.canonical_name).to eq 'Bar'

      a.name_en = 'Foo'
      expect(a.canonical_name).to eq 'Foo'
    end

    it 'should be nil if no translations' do
      a = AClass.new
      expect(a.canonical_name).to be_nil
      a.name_en = 'Foo'
      expect(a.canonical_name).not_to be_nil
      a.name_en = ''
      expect(a.canonical_name).to be_nil
    end

    it 'should not get stored if no canonical_name attrib available' do
      class BClass
        include Translatable
        translates :name
      end

      b = BClass.new
      b.name = 'Foo'
      expect{b.canonical_name}.to raise_error
    end

    it 'should be updated if name_translations gets updated directly' do
      a = AClass.new
      a.name_translations = {en: 'Foo'}
      expect(a.canonical_name).to eq 'Foo'
    end
  end

end