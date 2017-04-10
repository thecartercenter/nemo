require 'spec_helper'

class AClass
  include Translatable
  translates :name, :hint
  attr_accessor :canonical_name, :canonical_hint
end

describe "Translatable" do

  let(:a) { AClass.new }

  it "basic assignment and reading" do
    I18n.locale = :en

    expect(a.name).to eq(nil)
    expect(a.name_en).to eq(nil)
    expect(a.name(:fr)).to eq(nil)

    a.name_en = "foo"

    expect(a.name).to eq("foo")
    expect(a.name_en).to eq("foo")
    expect(a.name(:fr)).to eq(nil)
    expect(a.name(:fr, :strict => false)).to eq("foo")
    expect(a.name("fr", :strict => false)).to eq("foo")
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

  it "blanks" do
    a.name_en = ""
    expect(a.name_en).to be_nil
    expect(a.name_translations).to be_nil

    a.name_fr = "foo"
    a.name_en = ""
    expect(a.name_en).to be_nil
    expect(a.name_fr).to eq "foo"
  end

  it "available locales" do
    I18n.locale = :en

    expect(a.available_locales).to eq([])
    a.name_en = "foo"
    expect(a.available_locales).to eq([:en])
    a.hint_fr = "foo"
    expect(a.available_locales).to eq([:en, :fr])
    expect(a.available_locales(:except_current => true)).to eq([:fr])
  end

  it "all_blank" do
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
      a.name_en = 'Foo'
      expect(a.canonical_name).to eq 'Foo'
    end

    it 'should be first-entered locale if default is blank' do
      a.name_en = ''
      a.name_fr = 'Bar'
      expect(a.canonical_name).to eq 'Bar'

      a.name_en = 'Foo'
      expect(a.canonical_name).to eq 'Foo'
    end

    it 'should be first-entered locale if default is nil' do
      a.name_fr = 'Bar'
      expect(a.canonical_name).to eq 'Bar'

      a.name_en = 'Foo'
      expect(a.canonical_name).to eq 'Foo'
    end

    it 'should be nil if no translations' do
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
      expect{b.canonical_name}.to raise_error NoMethodError, /canonical_name/
    end

    it 'should be updated if name_translations gets updated directly' do
      a.name_translations = {en: 'Foo'}
      expect(a.canonical_name).to eq 'Foo'
    end
  end

  describe "direct assignment of foo_translations" do
    it "should remove blank values" do
      a.name_translations = { en: "Foo", fr: "" }
      expect(a.name_translations).to eq({ "en" => "Foo" })
    end

    it "should reset to nil if no non-blank translations" do
      a.name_translations = { en: "" }
      expect(a.name_translations).to be_nil
    end
  end

  describe "fallbacks" do
    before do
      a.name_en = "Eng"
      a.name_fr = "Fra"
    end

    it "should return nil if translation missing and fallbacks not given" do
      expect(a.name(:es)).to be_nil
    end

    it "should return french if given as first fallback" do
      expect(a.name(:es, fallbacks: [:fr])).to eq("Fra")
    end

    it "should return french if second fallback but first fallback not found" do
      expect(a.name(:es, fallbacks: [:de, :fr])).to eq("Fra")
    end

    it "should return english if strict mode and no fallbacks found" do
      expect(a.name(:es, strict: false, fallbacks: [:de, :it])).to eq("Eng")
    end
  end
end
