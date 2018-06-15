require 'rails_helper'

opts = configatron.translatable.default_options
configatron.translatable.default_options = nil

class Basic
  include Translatable
  translates :name, :hint
  attr_accessor :canonical_name, :canonical_hint
end

class NoCanonical
  include Translatable
  translates :name
end

class RestrictedLocales
  include Translatable
  translates :name, :hint, locales: %i(en fr es)
  attr_accessor :canonical_name, :canonical_hint
end

configatron.translatable.default_options = opts

describe "Translatable" do
  let(:obj) { Basic.new }

  it "basic assignment and reading" do
    I18n.locale = :en

    expect(obj.name).to eq(nil)
    expect(obj.name_en).to eq(nil)
    expect(obj.name(:fr)).to eq(nil)

    obj.name_en = "foo"

    expect(obj.name).to eq("foo")
    expect(obj.name_en).to eq("foo")
    expect(obj.name(:fr)).to eq(nil)
    expect(obj.name(:fr, :strict => false)).to eq("foo")
    expect(obj.name("fr", :strict => false)).to eq("foo")
    expect(obj.name_fr(:strict => false)).to eq("foo")

    obj.name = "bar"

    expect(obj.name).to eq("bar")
    expect(obj.name_en).to eq("bar")
    expect(obj.name(:fr)).to eq(nil)

    obj.name_fr = "feu"

    expect(obj.name(:fr)).to eq("feu")
    expect(obj.name("en")).to eq("bar")
    expect(obj.name).to eq("bar")

    obj.hint = "baz"

    expect(obj.name(:fr)).to eq("feu")
    expect(obj.name("en")).to eq("bar")
    expect(obj.hint("en")).to eq("baz")

    I18n.locale = :fr

    expect(obj.name).to eq("feu")

    obj.name = "zing"

    expect(obj.name).to eq("zing")
    expect(obj.name_fr).to eq("zing")
    expect(obj.name_en).to eq("bar")

    I18n.locale = :en

    expect(obj.name).to eq("bar")
  end

  it "blanks" do
    obj.name_en = ""
    expect(obj.name_en).to be_nil
    expect(obj.name_translations).to be_nil

    obj.name_fr = "foo"
    obj.name_en = ""
    expect(obj.name_en).to be_nil
    expect(obj.name_fr).to eq "foo"
  end

  it "available locales" do
    I18n.locale = :en

    expect(obj.available_locales).to eq([])
    obj.name_en = "foo"
    expect(obj.available_locales).to eq([:en])
    obj.hint_fr = "foo"
    expect(obj.available_locales).to eq([:en, :fr])
    expect(obj.available_locales(:except_current => true)).to eq([:fr])
  end

  it "all_blank" do
    obj.name_translations = nil
    expect(obj.name_all_blank?).to eq(true)
    obj.name_en = ""
    expect(obj.name_all_blank?).to eq(true)
    obj.name_en = "foo"
    expect(obj.name_all_blank?).to eq(false)
    obj.name_fr = "bar"
    obj.name_en = ""
    expect(obj.name_all_blank?).to eq(false)
    obj.name_fr = ""
    expect(obj.name_all_blank?).to eq(true)
    obj.name_fr = nil
    expect(obj.name_all_blank?).to eq(true)
  end

  describe 'canonical name' do
    it 'should be default locale if available' do
      obj.name_en = 'Foo'
      expect(obj.canonical_name).to eq 'Foo'
    end

    it 'should be first-entered locale if default is blank' do
      obj.name_en = ''
      obj.name_fr = 'Bar'
      expect(obj.canonical_name).to eq 'Bar'

      obj.name_en = 'Foo'
      expect(obj.canonical_name).to eq 'Foo'
    end

    it 'should be first-entered locale if default is nil' do
      obj.name_fr = 'Bar'
      expect(obj.canonical_name).to eq 'Bar'

      obj.name_en = 'Foo'
      expect(obj.canonical_name).to eq 'Foo'
    end

    it 'should be nil if no translations' do
      expect(obj.canonical_name).to be_nil
      obj.name_en = 'Foo'
      expect(obj.canonical_name).not_to be_nil
      obj.name_en = ''
      expect(obj.canonical_name).to be_nil
    end

    it 'should not get stored if no canonical_name attrib available' do
      b = NoCanonical.new
      b.name = 'Foo'
      expect { b.canonical_name }.to raise_error NoMethodError, /canonical_name/
    end

    it 'should be updated if name_translations gets updated directly' do
      obj.name_translations = {en: 'Foo'}
      expect(obj.canonical_name).to eq 'Foo'
    end
  end

  describe "direct assignment of foo_translations" do
    it "should remove blank values" do
      obj.name_translations = { en: "Foo", fr: "" }
      expect(obj.name_translations).to eq({ "en" => "Foo" })
    end

    it "should reset to nil if no non-blank translations" do
      obj.name_translations = { en: "" }
      expect(obj.name_translations).to be_nil
    end
  end

  describe "fallbacks" do
    before do
      obj.name_en = "Eng"
      obj.name_fr = "Fra"
    end

    it "should return nil if translation missing and fallbacks not given" do
      expect(obj.name(:es)).to be_nil
    end

    it "should return french if given as first fallback" do
      expect(obj.name(:es, fallbacks: [:fr])).to eq("Fra")
    end

    it "should return french if second fallback but first fallback not found" do
      expect(obj.name(:es, fallbacks: [:de, :fr])).to eq("Fra")
    end

    it "should return english if strict mode and no fallbacks found" do
      expect(obj.name(:es, strict: false, fallbacks: [:de, :it])).to eq("Eng")
    end
  end

  describe "locale restrictions" do
    context "with restriction set at class level" do
      let(:obj) { RestrictedLocales.new }

      context "with allowed translations available" do
        before do
          obj.name_en = "Eng"
          obj.name_fr = "Fra"
          obj.name_it = "Ita"
        end

        it "should work normally for an allowed locale" do
          expect(obj.name_en).to eq "Eng"
        end

        it "should not return a disallowed locale and return nil instead if strict mode on" do
          expect(obj.name(:it, strict: true)).to be_nil
        end

        it "should not return a disallowed locale and fallback to an allowed one if strict mode off" do
          expect(obj.name(:it, strict: false)).to eq "Eng"
        end
      end

      context "with only disallowed locales available" do
        before do
          obj.name_it = "Ita"
        end

        it "should return nil rather than the disallowed locale" do
          expect(obj.name).to be_nil
        end

        it "should return nil even if Italian given as explicit fallback" do
          expect(obj.name(:en, fallbacks: [:it])).to be_nil
        end
      end
    end

    context "with restriction set globally as proc" do
      it "should respect the setting" do
        # default_options are copied in when `translates` is called, so we have to do it this way.
        allowed = nil
        configatron.translatable.default_options = {locales: -> { allowed }}
        class X
          include Translatable
          translates :name
        end

        obj = X.new
        obj.name_it = "Ita"

        allowed = %i(en fr)
        expect(obj.name).to be_nil

        allowed = %i(en it)
        expect(obj.name).to eq "Ita"

        configatron.translatable.default_options = nil
      end
    end
  end
end
