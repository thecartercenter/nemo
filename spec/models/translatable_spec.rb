# frozen_string_literal: true

require "rails_helper"

class Basic
  include ActiveModel::Model
  include Translatable
  translates :name, :hint
  attr_accessor :mission_id, :canonical_name, :canonical_hint
end

class NoCanonical
  include ActiveModel::Model
  include Translatable
  translates :name
  attr_accessor :mission_id
end

describe "Translatable" do
  let(:preferred_locales_str) { "en,fr" }
  let(:mission) { create(:mission, setting: build(:setting, preferred_locales_str: preferred_locales_str)) }
  let(:obj) { Basic.new(mission_id: mission.id) }

  it "basic assignment and reading" do
    I18n.locale = :en

    expect(obj.name).to eq(nil)
    expect(obj.name_en).to eq(nil)
    expect(obj.name(:fr)).to eq(nil)

    obj.name_en = "foo"

    expect(obj.name).to eq("foo")
    expect(obj.name_en).to eq("foo")
    expect(obj.name(:fr)).to eq(nil)
    expect(obj.name(:fr, fallbacks: true)).to eq("foo")
    expect(obj.name("fr", fallbacks: true)).to eq("foo")
    expect(obj.name_fr(fallbacks: true)).to eq("foo")

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

  it "blanks and whitespace" do
    obj.name_en = ""
    expect(obj.name_en).to be_nil
    expect(obj.name_translations).to be_nil

    obj.name_fr = "foo"
    obj.name_en = " "
    expect(obj.name_en).to be_nil
    expect(obj.name_fr).to eq("foo")
  end

  it "available locales" do
    I18n.locale = :en

    expect(obj.available_locales).to eq([])
    obj.name_en = "foo"
    expect(obj.available_locales).to eq([:en])
    obj.hint_fr = "foo"
    expect(obj.available_locales).to eq(%i[en fr])
    expect(obj.available_locales(except_current: true)).to eq([:fr])
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

  describe "canonical name" do
    it "should be default locale if available" do
      obj.name_en = "Foo"
      expect(obj.canonical_name).to eq("Foo")
    end

    it "should be first-entered locale if default is blank" do
      obj.name_en = ""
      obj.name_fr = "Bar"
      expect(obj.canonical_name).to eq("Bar")

      obj.name_en = "Foo"
      expect(obj.canonical_name).to eq("Foo")
    end

    it "should be first-entered locale if default is nil" do
      obj.name_fr = "Bar"
      expect(obj.canonical_name).to eq("Bar")

      obj.name_en = "Foo"
      expect(obj.canonical_name).to eq("Foo")
    end

    it "should be nil if no translations" do
      expect(obj.canonical_name).to be_nil
      obj.name_en = "Foo"
      expect(obj.canonical_name).not_to be_nil
      obj.name_en = ""
      expect(obj.canonical_name).to be_nil
    end

    it "should not get stored if no canonical_name attrib available" do
      b = NoCanonical.new(mission_id: mission.id)
      b.name = "Foo"
      expect { b.canonical_name }.to raise_error(NoMethodError, /canonical_name/)
    end

    it "should be updated if name_translations gets updated directly" do
      obj.name_translations = {en: "Foo"}
      expect(obj.canonical_name).to eq("Foo")
    end
  end

  describe "direct assignment of foo_translations" do
    it "should remove blank values" do
      obj.name_translations = {en: "Foo", fr: ""}
      expect(obj.name_translations).to eq("en" => "Foo")
    end

    it "should reset to nil if no non-blank translations" do
      obj.name_translations = {en: ""}
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

    it "should return english if fallbacks allowed" do
      expect(obj.name(:es, fallbacks: true)).to eq("Eng")
    end
  end

  describe "locale restrictions" do
    context "with italian not permitted" do
      let(:obj) { Basic.new(mission_id: mission.id) }
      let(:preferred_locales_str) { "en,fr" }

      context "with allowed translations available" do
        before do
          obj.name_en = "Eng"
          obj.name_fr = "Fra"
          obj.name_it = "Ita"
        end

        it "should work normally for an allowed locale" do
          expect(obj.name_en).to eq("Eng")
        end

        it "should not return a disallowed locale and return nil instead if fallbacks disallowed" do
          expect(obj.name(:it)).to be_nil
        end

        it "should not return a disallowed locale and fallback to an allowed one if fallbacks allowed" do
          expect(obj.name(:it, fallbacks: true)).to eq("Eng")
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

    context "with no mission set" do
      let(:obj) { Basic.new(mission_id: nil) }

      before do
        Setting.root.update!(preferred_locales_str: "en,fr")
        obj.name_en = "Eng"
        obj.name_fr = "Fra"
        obj.name_it = "Ita"
      end

      it "should use the root setting and also restrict" do
        expect(obj.name(:it)).to be_nil
      end
    end

    context "when italian allowed and available" do
      let(:preferred_locales_str) { "en,fr,it" }

      before do
        obj.name_en = "Eng"
        obj.name_fr = "Fra"
        obj.name_it = "Ita"
      end

      it "should use italian" do
        expect(obj.name(:it)).to eq("Ita")
      end
    end
  end
end
