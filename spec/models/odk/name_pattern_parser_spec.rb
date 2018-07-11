# frozen_string_literal: true

require "rails_helper"

describe Odk::NamePatternParser do
  subject(:output) { described_class.new(pattern, src_item: form.root_group).to_odk }

  describe "xpath route handling" do
    let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
    let(:g2) { Odk::QingGroupDecorator.decorate(form.sorted_children[1]) }
    let(:q21) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[0]) }
    let(:q22) { Odk::QingDecorator.decorate(form.sorted_children[1].sorted_children[1]) }
    let(:g3) { Odk::QingGroupDecorator.decorate(form.sorted_children[2]) }
    let(:q31) { Odk::QingDecorator.decorate(form.sorted_children[2].sorted_children[0]) }
    let(:q31a) { Odk::QingDecorator.decorate(form.sorted_children[2].sorted_children[0]).subqings.first }

    before do
      q1.update!(code: "Q1")
      q21.update!(code: "Q21")
      q22.update!(code: "Q22")
      q31.update!(code: "Q31")
    end

    context "without select questions" do
      let(:form) { create(:form, question_types: ["text", %w[text text], ["text"]]) }

      context "$ phrase with question code" do
        let(:pattern) { "Person: $Q22" }
        it { is_expected.to eq(%(Person: <output value="/data/#{g2.odk_code}/#{q22.odk_code}" />)) }
      end

      context "two $'s separated by only whitespace" do
        let(:pattern) { "Person: $Q21 $Q22" }
        it "replaces with &#160;" do
          is_expected.to eq(+%(Person: <output value="/data/#{g2.odk_code}/#{q21.odk_code}" />&#160;) <<
            %(<output value="/data/#{g2.odk_code}/#{q22.odk_code}" />))
        end
      end

      context "with invalid code" do
        let(:pattern) { "hai $Junk foo" }
        it { is_expected.to eq("hai  foo") }
      end

      context "with double quotes in pattern" do
        let(:pattern) { %(hai $Q21 "foo") }
        it { is_expected.to eq(%(hai <output value="/data/#{g2.odk_code}/#{q21.odk_code}" /> "foo")) }
      end
    end

    context "with select questions" do
      let(:form) { create(:form, question_types: ["text", %w[select_one text], ["multilevel_select_one"]]) }

      context "with code referencing regular select" do
        let(:pattern) { "Ice Cream: $Q21" }

        it "uses the option name and coalesce" do
          is_expected.to eq(+%(Ice Cream: <output value=) <<
            %("jr:itext(coalesce(/data/#{g2.odk_code}/#{q21.odk_code},'blank'))" />))
        end
      end

      context "with code referencing multilevel select" do
        let(:pattern) { "Ice Cream: $Q31" }

        it "uses the option name and coalesce" do
          is_expected.to eq(+%(Ice Cream: <output value=) <<
            %("jr:itext(coalesce(/data/#{g3.odk_code}/#{q31a.odk_code},'blank'))" />))
        end
      end
    end
  end

  describe "calc()" do
    let(:form) { create(:form, question_types: %w[integer integer]) }
    let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }

    before do
      q1.update!(code: "Q1")
    end

    context "with simple expression" do
      let(:pattern) { "calc($Q1 + 2)" }
      it { is_expected.to eq(%(<output value="/data/#{q1.odk_code} + 2" />)) }
    end

    context "with quoted string containing $" do
      let(:pattern) { "calc(myfunc((5 + 12) / $Q1, ' (($money cash'))" }
      it do
        is_expected.to eq(%{<output value="myfunc((5 + 12) / /data/#{q1.odk_code}, ' (($money cash')" />})
      end
    end

    context "with invalid code" do
      let(:pattern) { "calc($Junk + 7)" }
      it { is_expected.to eq(%(<output value="'' + 7" />)) }
    end

    context "with double quotes in pattern" do
      let(:pattern) { %{calc(myfunc($Q1,'"foo"'))} }
      it do
        is_expected.to eq(+%(<output value=") <<
          %{myfunc(/data/#{q1.odk_code},'&quot;foo&quot;')" />})
      end
    end
  end
end
