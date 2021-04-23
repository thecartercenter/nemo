# frozen_string_literal: true

require "rails_helper"

describe ODK::ResponsePatternParser do
  subject(:output) { described_class.new(pattern, src_item: src_item).to_odk }

  describe "xpath route handling" do
    let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
    let(:g2) { ODK::QingGroupDecorator.decorate(form.c[1]) }
    let(:q21) { ODK::QingDecorator.decorate(form.c[1].c[0]) }
    let(:q22) { ODK::QingDecorator.decorate(form.c[1].c[1]) }
    let(:g3) { ODK::QingGroupDecorator.decorate(form.c[2]) }
    let(:q31) { ODK::QingDecorator.decorate(form.c[2].c[0]) }
    let(:q31b) { ODK::QingDecorator.decorate(form.c[2].c[0]).subqings[1] }
    let(:q4a) { ODK::QingDecorator.decorate(form.c[3]).subqings[0] }
    let(:g2path) { "/data/#{g2.odk_code}" }
    let(:q21path) { "/data/#{g2.odk_code}/#{q21.odk_code}" }
    let(:g3path) { "/data/#{g3.odk_code}" }
    let(:q31path) { "/data/#{g3.odk_code}/#{q31.odk_code}" }
    let(:q31bpath) { "/data/#{g3.odk_code}/#{q31b.odk_code}" }
    let(:q4apath) { "/data/#{q4a.odk_code}" }

    before do
      q1.question.update!(code: "Q1")
      q21.question.update!(code: "Q21")
      q22.question.update!(code: "Q22")
      q31.question.update!(code: "Q31")
      q4a.question.update!(code: "Q4")
    end

    context "with all text questions" do
      let(:form) { create(:form, question_types: ["text", %w[text text], ["text"], "text"]) }

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
      let(:form) do
        create(:form, question_types: ["text", %w[select_one text],
                                       ["multilevel_select_one"], "super_multilevel_select_one"])
      end

      before do
        stub_const(ODK::OptionSetDecorator, "EXTERNAL_CSV_METHOD_THRESHOLD", 7)
      end

      context "with code referencing regular select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q21-x" }
        it do
          is_expected.to eq("concat('hai-',"\
            "jr:itext(coalesce(indexed-repeat(#{q21path},#{g2path},1),'BLANK')),'-x')")
        end
      end

      context "with code referencing smaller multilevel select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q31-x" }

        it "uses the lowest subquestion" do
          is_expected.to eq("concat('hai-',"\
            "jr:itext(coalesce(indexed-repeat(#{q31bpath},#{g3path},1),'BLANK')),'-x')")
        end
      end

      context "with code referencing larger multilevel select" do
        let(:src_item) { q1 }
        let(:pattern) { "hai-$Q4-x" }

        it "uses the top level subquestion" do
          is_expected.to eq("concat('hai-',jr:itext(coalesce(#{q4apath},'BLANK')),'-x')")
        end
      end
    end
  end

  describe "numeric literal handling" do
    let(:form) { create(:form, question_types: %w[integer decimal]) }
    let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
    let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }

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

  # rubocop:disable Layout/LineLength
  describe "Dynamic question value $questionCode:value" do
    context "should not recognize the pattern as a token" do
      let(:likert_options) { create(:option_set, option_names: %w[Excellent Good Bad], option_values: [1, 2, 3]) }
      let(:likert_question) { create(:question, code: "likert1", qtype_name: "select_one", option_set: likert_options) }
      let(:score) { create(:question, code: "score1", qtype_name: "integer") }
      let(:form) { create(:form, :live, name: "Dynamic answers for option sets", questions: [likert_question, score]) }
      let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
      let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }

      let(:src_item) { q2 }
      let(:pattern) { "calc(likert1:value)" }

      it "should have correct xpath" do
        is_expected.to eq("likert1:value")
      end
    end

    context "should use labels as xpath if values are not used" do
      let(:likert_options) { create(:option_set, option_names: %w[Excellent Good Bad], option_values: [1, 2, 3]) }
      let(:likert_options2) { create(:option_set, option_names: %w[OK Whatever Bad], option_values: [4, 5, 6]) }
      let(:likert_question) { create(:question, code: "likert1", qtype_name: "select_one", option_set: likert_options) }
      let(:likert_question2) { create(:question, code: "likert2", qtype_name: "select_one", option_set: likert_options2) }
      let(:score) { create(:question, code: "score1", qtype_name: "integer") }
      let(:form) { create(:form, :live, name: "Dynamic answers for option sets", questions: [likert_question, likert_question2, score]) }
      let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
      let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }
      let(:q3) { ODK::QingDecorator.decorate(form.c[2]) }

      let(:src_item) { q3 }
      let(:pattern) { "calc($likert1 + $likert2)" }

      it "should have correct xpath" do
        is_expected.to eq("(jr:itext(coalesce(/data/#{q1.odk_code},'BLANK'))) + (jr:itext(coalesce(/data/#{q2.odk_code},'BLANK')))")
      end
    end

    context "for one default answer value calculation" do
      let(:likert_options) { create(:option_set, option_names: %w[Excellent Good Bad], option_values: [1, 2, 3]) }
      let(:likert_question) { create(:question, code: "likert1", qtype_name: "select_one", option_set: likert_options) }
      let(:score) { create(:question, code: "score1", qtype_name: "integer") }
      let(:form) { create(:form, :live, name: "Dynamic answers for option sets", questions: [likert_question, score]) }
      let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
      let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }

      let(:src_item) { q2 }
      let(:pattern) { "calc($likert1:value)" }

      it "should have correct xpath" do
        is_expected.to eq("(instance('os#{likert_options.id}_numeric_values')/root/item[itextId=/data/#{q1.odk_code}]/numericValue)")
      end
    end

    context "for default answer value with two calculations" do
      let(:likert_options) { create(:option_set, option_names: %w[Excellent Good Bad], option_values: [1, 2, 3]) }
      let(:likert_options2) { create(:option_set, option_names: %w[OK Whatever Bad], option_values: [4, 5, 6]) }
      let(:likert_question) { create(:question, code: "likert1", qtype_name: "select_one", option_set: likert_options) }
      let(:likert_question2) { create(:question, code: "likert2", qtype_name: "select_one", option_set: likert_options2) }
      let(:score) { create(:question, code: "score1", qtype_name: "integer") }
      let(:form) { create(:form, :live, name: "Dynamic answers for option sets", questions: [likert_question, likert_question2, score]) }
      let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
      let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }
      let(:q3) { ODK::QingDecorator.decorate(form.c[2]) }

      let(:src_item) { q3 }
      let(:pattern) { "calc($likert1:value + $likert2:value)" }

      it "should have correct xpath" do
        is_expected.to eq("(instance('os#{likert_options.id}_numeric_values')/root/item[itextId=/data/#{q1.odk_code}]/numericValue) + (instance('os#{likert_options2.id}_numeric_values')/root/item[itextId=/data/#{q2.odk_code}]/numericValue)")
      end
    end
  end

  # rubocop:enable Layout/LineLength

  describe "calc()" do
    let(:form) { create(:form, question_types: %w[integer text integer]) }
    let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
    let(:q2) { ODK::QingDecorator.decorate(form.c[1]) }
    let(:q3) { ODK::QingDecorator.decorate(form.c[2]) }

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
        let(:pattern) { "calc(myfunc((5 + 12) div $Q1, ' (($money cash'))" }
        it { is_expected.to eq("myfunc((5 + 12) div (/data/#{q1.odk_code}), ' (($money cash')") }
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
