# frozen_string_literal: true

require "rails_helper"

describe Odk::ResponsePatternParser do
  subject(:output) { described_class.new(pattern, src_item: src_item).to_odk }

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

    context "with all text questions" do
      let(:form) { create(:form, question_types: ["text", %w[text text], ["text"]]) }

      context "for root src_item" do
        let(:src_item) { form.root_group }

        context "with RepeatNum" do
          let(:pattern) { "Num $!RepeatNum $Q31" }
          it do
            is_expected.to eq("concat('Num ',' ',"\
              "indexed-repeat(/data/#{g3.odk_code}/#{q31.odk_code},/data/#{g3.odk_code},1))")
          end
        end
      end

      context "for top level src_item" do
        let(:src_item) { q1 }

        context "with RepeatNum" do
          let(:pattern) { "Num $!RepeatNum" }
          it { is_expected.to eq("'Num '") }
        end
      end

      context "for src_item in repeat group" do
        let(:src_item) { q22 }

        context "with no codes" do
          let(:pattern) { "hai" }
          it { is_expected.to eq("'hai'") }
        end

        context "with local code" do
          let(:pattern) { "hai-$Q21-thar" }
          it { is_expected.to eq("concat('hai-',../#{q21.odk_code},'-thar')") }
        end

        context "with code referencing question in other group" do
          let(:pattern) { "hai-$Q31-thar" }

          it do
            is_expected.to eq("concat('hai-',"\
              "indexed-repeat(/data/#{g3.odk_code}/#{q31.odk_code},/data/#{g3.odk_code},1),'-thar')")
          end
        end

        context "with repeat num" do
          let(:pattern) { "hai-$!RepeatNum-thar" }
          it { is_expected.to eq("concat('hai-',position(..),'-thar')") }
        end

        context "with invalid code" do
          let(:pattern) { "hai $Junk foo" }
          it { is_expected.to eq("concat('hai ',' foo')") }
        end
      end
    end

    context "with select questions" do
      let(:form) { create(:form, question_types: ["text", %w[select_one text], ["multilevel_select_one"]]) }

      context "with code referencing regular select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q21-x" }
        it do
          is_expected.to eq("concat('hai-',"\
            "jr:itext(indexed-repeat(/data/#{g2.odk_code}/#{q21.odk_code},/data/#{g2.odk_code},1)),'-x')")
        end
      end

      context "with code referencing multilevel select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q31-x" }
        it do
          is_expected.to eq("concat('hai-',"\
            "jr:itext(indexed-repeat(/data/#{g3.odk_code}/#{q31a.odk_code},/data/#{g3.odk_code},1)),'-x')")
        end
      end
    end
  end

  describe "calc()" do
    let(:form) { create(:form, question_types: %w[integer integer]) }
    let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
    let(:q2) { Odk::QingDecorator.decorate(form.sorted_children[1]) }
    let(:src_item) { q2 }

    before do
      q1.update!(code: "Q1")
    end

    context "with simple expression" do
      let(:pattern) { "calc($Q1 + 2)" }
      it { is_expected.to eq("/data/#{q1.odk_code} + 2") }
    end

    context "with quoted string containing $" do
      let(:pattern) { "calc(concat((5 + 12) / $Q1, ' (($money cash'))" }
      it { is_expected.to eq("concat((5 + 12) / /data/#{q1.odk_code}, ' (($money cash')") }
    end

    context "with invalid code" do
      let(:pattern) { "calc($Junk + 7)" }
      it { is_expected.to eq("'' + 7") }
    end
  end
end
