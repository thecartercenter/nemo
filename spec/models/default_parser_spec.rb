require "spec_helper"

describe DefaultParser do
  let(:form) { create(:form, question_types: ["text", ["text", "text"], ["text"]]) }
  let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
  let(:q21) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[0]) }
  let(:q22) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[1]) }
  let(:g3) { Odk::QingGroupDecorator.decorate(form.sorted_children[2]) }
  let(:q31) { Odk::QingDecorator.decorate(form.sorted_children[2].sorted_children[0]) }
  subject { described_class.new(q22).to_odk }

  before do
    q1.update!(code: "Q1")
    q21.update!(code: "Q21")
    q22.update!(code: "Q22", default: pattern)
    q31.update!(code: "Q31")
  end

  context "with no codes" do
    let(:pattern) { "hai" }

    it "should be correct" do
      expect(subject).to eq "concat('hai')"
    end
  end

  context "with local code" do
    let(:pattern) { "hai-$Q21-thar" }

    it "should be correct" do
      expect(subject).to eq "concat('hai-',../#{q21.odk_code},'-thar')"
    end
  end

  context "with code to other group" do
    let(:pattern) { "hai-$Q31-thar" }

    it "should be correct" do
      expect(subject).to eq(
        "concat('hai-',indexed-repeat(/data/#{g3.odk_code}/#{q31.odk_code},/data/#{g3.odk_code},1),'-thar')")
    end
  end

  context "with repeat num" do
    let(:pattern) { "hai-$!RepeatNum-thar" }

    it "should be correct" do
      expect(subject).to eq "concat('hai-',position(..),'-thar')"
    end
  end
end
