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
    let(:g2path) { "/data/#{g2.odk_code}" }
    let(:q21path) { "/data/#{g2.odk_code}/#{q21.odk_code}" }
    let(:g3path) { "/data/#{g3.odk_code}" }
    let(:q31path) { "/data/#{g3.odk_code}/#{q31.odk_code}" }
    let(:q31apath) { "/data/#{g3.odk_code}/#{q31a.odk_code}" }

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
          it { is_expected.to eq("concat('Num ',' ',indexed-repeat(#{q31path},#{g3path},1))") }
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
          let(:pattern) { "hai there" }
          it { is_expected.to eq("'hai there'") }
        end

        context "with local code" do
          let(:pattern) { "hai-$Q21-thar" }
          it { is_expected.to eq("concat('hai-',../#{q21.odk_code},'-thar')") }
        end

        context "with code referencing question in other group" do
          let(:pattern) { "hai-$Q31-thar" }

          it { is_expected.to eq("concat('hai-',indexed-repeat(#{q31path},#{g3path},1),'-thar')") }
        end

        context "with repeat num" do
          let(:pattern) { "hai-$!RepeatNum-thar" }
          it { is_expected.to eq("concat('hai-',position(..),'-thar')") }
        end

        context "with invalid code" do
          let(:pattern) { "hai $Junk foo" }
          it { is_expected.to eq("concat('hai ',' foo')") }
        end

        context "with single and double quotes" do
          let(:pattern) { %("hai" $Q1 b'y) }
          it { is_expected.to eq(%{concat('"hai" ',/data/#{q1.odk_code},' b’y')}) }
        end
      end
    end

    context "with select questions" do
      let(:form) { create(:form, question_types: ["text", %w[select_one text], ["multilevel_select_one"]]) }

      context "with code referencing regular select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q21-x" }
        it { is_expected.to eq("concat('hai-',jr:itext(indexed-repeat(#{q21path},#{g2path},1)),'-x')") }
      end

      context "with code referencing multilevel select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q31-x" }
        it { is_expected.to eq("concat('hai-',jr:itext(indexed-repeat(#{q31apath},#{g3path},1)),'-x')") }
      end
    end
  end

  describe "numeric literal handling" do
    let(:form) { create(:form, question_types: %w[integer decimal]) }
    let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
    let(:q2) { Odk::QingDecorator.decorate(form.sorted_children[1]) }

    context "for integer question" do
      let(:src_item) { q1 }
      let(:pattern) { "-123" }
      it { is_expected.to eq("-123") }
    end

    context "for decimal question" do
      let(:src_item) { q2 }
      let(:pattern) { "-12.34" }
      it { is_expected.to eq("-12.34") }
    end
  end

  describe "calc()" do
    let(:form) { create(:form, question_types: %w[integer text integer]) }
    let(:q1) { Odk::QingDecorator.decorate(form.sorted_children[0]) }
    let(:q2) { Odk::QingDecorator.decorate(form.sorted_children[1]) }
    let(:q3) { Odk::QingDecorator.decorate(form.sorted_children[2]) }

    before do
      q1.update!(code: "Q1")
    end

    context "with text src question" do
      let(:src_item) { q2 }

      context "with simple expression" do
        let(:pattern) { "calc($Q1 + 2)" }
        it { is_expected.to eq("(/data/#{q1.odk_code}) + 2") }
      end

      context "with quoted string containing $" do
        let(:pattern) { "calc(myfunc((5 + 12) / $Q1, ' (($money cash'))" }
        it { is_expected.to eq("myfunc((5 + 12) / (/data/#{q1.odk_code}), ' (($money cash')") }
      end

      context "with invalid code" do
        let(:pattern) { "calc($Junk + 7)" }
        it { is_expected.to eq("('') + 7") }
      end

      context "with single and double quotes" do
        let(:pattern) { %{calc(myfunc('"hai"', $Q1, "'foo’s'"))} }
        it { is_expected.to eq(%{myfunc('"hai"', (/data/#{q1.odk_code}), "'foo’s'")}) }
      end
    end

    context "with numeric src question" do
      let(:src_item) { q3 }

      context "with simple expression" do
        let(:pattern) { "calc($Q1 + 2)" }
        it { is_expected.to eq("(/data/#{q1.odk_code}) + 2") }
      end
    end
  end
end
