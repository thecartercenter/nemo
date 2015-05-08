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

    expect(a.name).to eq(nil)
    expect(a.name_en).to eq(nil)
    expect(a.name(:fr)).to eq(nil)

    a.name_en = "foo"

    expect(a.name).to eq("foo")
    expect(a.name_en).to eq("foo")
    expect(a.name(:fr)).to eq(nil)
    expect(:strict => false)).to eq("foo", a.name(:fr)
    expect(:strict => false)).to eq("foo", a.name("fr")
    expect(a.name_fr(:strict => false)).to eq("foo")

    a.name = "bar"

    expect(a.name).to eq("bar")
    expect(a.name_en).to eq("bar")
    expect(a.name(:fr)).to eq(nil)

    a.name_fr = "feu"

    expect(a.name(:fr)).to eq("feu")
    expect(a.name("en")).to eq("bar")
    expect(a.name).to eq("bar")

    a.hint = "baz"

    expect(a.name(:fr)).to eq("feu")
    expect(a.name("en")).to eq("bar")
    expect(a.hint("en")).to eq("baz")

    I18n.locale = :fr

    expect(a.name).to eq("feu")

    a.name = "zing"

    expect(a.name).to eq("zing")
    expect(a.name_fr).to eq("zing")
    expect(a.name_en).to eq("bar")

    I18n.locale = :en

    expect(a.name).to eq("bar")
  end

  it 'available locales' do
    a = AClass.new
    I18n.locale = :en

    expect(a.available_locales).to eq([])
    a.name_en = "foo"
    expect(a.available_locales).to eq([:en])
    a.hint_fr = "foo"
    expect(a.available_locales).to eq([:en, :fr])
    expect(a.available_locales(:except_current => true)).to eq([:fr])
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
    expect(a.name_all_blank?).to eq(true)
    a.name_en = ""
    expect(a.name_all_blank?).to eq(true)
    a.name_en = "foo"
    expect(a.name_all_blank?).to eq(false)
    a.name_fr = "bar"
    a.name_en = ""
    expect(a.name_all_blank?).to eq(false)
    a.name_fr = ""
    expect(a.name_all_blank?).to eq(true)
    a.name_fr = nil
    expect(a.name_all_blank?).to eq(true)
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