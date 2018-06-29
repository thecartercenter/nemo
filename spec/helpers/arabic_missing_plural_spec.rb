require "rails_helper"

describe "arabic missing plurals" do
  context "with all plurals given" do
    before do
      setup_pluralizations(
        zero: "zero",
        one: "one",
        two: "two",
        few: "few",
        many: "many",
        other: "other"
      )
    end

    it "should translate properly" do
      expect(I18n.translate("pltest", locale: :ar, count: 0)).to eq("zero")
      expect(I18n.translate("pltest", locale: :ar, count: 1)).to eq("one")
      expect(I18n.translate("pltest", locale: :ar, count: 2)).to eq("two")
      expect(I18n.translate("pltest", locale: :ar, count: 3)).to eq("few")
      expect(I18n.translate("pltest", locale: :ar, count: 99)).to eq("many")
      expect(I18n.translate("pltest", locale: :ar, count: 100)).to eq("other")
    end
  end

  context "with only english-style plurals given" do
    before do
      setup_pluralizations(
        one: "one",
        other: "other"
      )
    end

    it "should translate properly" do
      expect(I18n.translate("pltest", locale: :ar, count: 0)).to eq("other")
      expect(I18n.translate("pltest", locale: :ar, count: 1)).to eq("one")
      expect(I18n.translate("pltest", locale: :ar, count: 2)).to eq("other")
      expect(I18n.translate("pltest", locale: :ar, count: 3)).to eq("other")
      expect(I18n.translate("pltest", locale: :ar, count: 99)).to eq("other")
      expect(I18n.translate("pltest", locale: :ar, count: 100)).to eq("other")
    end
  end

  context "with no plurals given" do
    before do
      setup_pluralizations("foo")
    end

    it "should translate properly" do
      expect(I18n.translate("pltest", locale: :ar, count: 0)).to eq("foo")
      expect(I18n.translate("pltest", locale: :ar, count: 1)).to eq("foo")
      expect(I18n.translate("pltest", locale: :ar, count: 2)).to eq("foo")
      expect(I18n.translate("pltest", locale: :ar, count: 3)).to eq("foo")
      expect(I18n.translate("pltest", locale: :ar, count: 99)).to eq("foo")
      expect(I18n.translate("pltest", locale: :ar, count: 100)).to eq("foo")
    end
  end

  def setup_pluralizations(value)
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:ar, pltest: value)
  end
end
