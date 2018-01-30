require "spec_helper"

describe Odk::NamePatternParser do
  let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
  let(:g2) { Odk::QingGroupDecorator.decorate(form.sorted_children[1]) }
  let(:q21) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[0]) }
  let(:q22) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[1]) }
  let(:g3) { Odk::QingGroupDecorator.decorate(form.sorted_children[2]) }
  let(:q31) { Odk::QingDecorator.decorate(form.sorted_children[2].sorted_children[0]) }
  let(:q31a) { Odk::QingDecorator.decorate(form.sorted_children[2].sorted_children[0]).subqings.first }
  subject { described_class.new(pattern, src_item: form.root_group).to_odk }

  before do
    q1.update!(code: "Q1")
    q21.update!(code: "Q21")
    q22.update!(code: "Q22")
    q31.update!(code: "Q31")
  end

  context "without select questions" do
    let(:form) { create(:form, question_types: ["text", ["text", "text"], ["text"]]) }

    context "$ phrase with question code" do
      let(:pattern) { "Person: $Q22" }
      it { is_expected.to eq %Q{Person: <output value="/data/#{g2.odk_code}/#{q22.odk_code}"/>} }
    end

    context "two $'s separated by only whitespace" do
      let(:pattern) { "Person: $Q21 $Q22" }
      it "replaces with &#160;" do
        is_expected.to eq %Q{Person: <output value="/data/#{g2.odk_code}/#{q21.odk_code}"/>&#160;} <<
          %Q{<output value="/data/#{g2.odk_code}/#{q22.odk_code}"/>}
      end
    end
  end

  context "with select questions" do
    let(:form) { create(:form, question_types: ["text", ["select_one", "text"], ["multilevel_select_one"]]) }

    context "with code referencing regular select" do
      let(:pattern) { "Ice Cream: $Q21" }

      it "uses the option name and coalesce" do
        is_expected.to eq %Q{Ice Cream: <output value="jr:itext(coalesce(/data/#{g2.odk_code}/#{q21.odk_code},'blank'))"/>}
      end
    end

    context "with code referencing multilevel select" do
      let(:pattern) { "Ice Cream: $Q31" }

      it "uses the option name and coalesce" do
        is_expected.to eq %Q{Ice Cream: <output value="jr:itext(coalesce(/data/#{g3.odk_code}/#{q31a.odk_code},'blank'))"/>}
      end
    end
  end
end