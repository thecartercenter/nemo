# frozen_string_literal: true

require "rails_helper"

describe ODK::NamePatternParser do
  subject(:output) { described_class.new(pattern, src_item: form.root_group).to_odk }

  describe "xpath route handling" do
    let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
    let(:g2) { ODK::QingGroupDecorator.decorate(form.c[1]) }
    let(:q21) { ODK::QingDecorator.decorate(form.c[1].c[0]) }
    let(:q22) { ODK::QingDecorator.decorate(form.c[1].c[1]) }
    let(:g3) { ODK::QingGroupDecorator.decorate(form.c[2]) }
    let(:q31) { ODK::QingDecorator.decorate(form.c[2].c[0]) }
    let(:q31b) { ODK::QingDecorator.decorate(form.c[2].c[0]).subqings[1] }
    let(:q4a) { ODK::QingDecorator.decorate(form.c[3]).subqings[0] }
    let(:q21path) { "/data/#{g2.odk_code}/#{q21.odk_code}" }
    let(:q22path) { "/data/#{g2.odk_code}/#{q22.odk_code}" }
    let(:q31bpath) { "/data/#{g3.odk_code}/#{q31b.odk_code}" }
    let(:q4apath) { "/data/#{q4a.odk_code}" }

    before do
      q1.question.update!(code: "Q1")
      q21.question.update!(code: "Q21")
      q22.question.update!(code: "Q22")
      q31.question.update!(code: "Q31")
      q4a.question.update!(code: "Q4")
    end

    context "without select questions" do
      let(:form) { create(:form, question_types: ["text", %w[text text], ["text"], "text"]) }

      context "$ phrase with question code" do
        let(:pattern) { "Person: $Q22" }
        it { is_expected.to eq(%(Person: <output value="#{q22path}" />)) }
      end

      context "two $'s separated by only whitespace" do
        let(:pattern) { "Person: $Q21 $Q22" }
        it "replaces with &#160;" do
          is_expected.to eq(%(Person: <output value="#{q21path}" />&#160;<output value="#{q22path}" />))
        end
      end

      context "with invalid code" do
        let(:pattern) { "hai $Junk foo" }
        it { is_expected.to eq("hai  foo") }
      end

      context "with single and double quotes in pattern" do
        let(:pattern) { %(hai $Q21 "foo's") }
        it { is_expected.to eq(%(hai <output value="#{q21path}" /> "foo’s")) }
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
        let(:pattern) { "Ice Cream: $Q21" }

        it "uses the option name and coalesce" do
          is_expected.to eq(%(Ice Cream: <output value="jr:itext(coalesce(#{q21path},&#39;BLANK&#39;))" />))
        end
      end

      context "with code referencing smaller multilevel select" do
        let(:pattern) { "Ice Cream: $Q31" }

        it "uses the lowest subquestion" do
          is_expected.to eq(%(Ice Cream: <output value="jr:itext(coalesce(#{q31bpath},&#39;BLANK&#39;))" />))
        end
      end

      context "with code referencing larger multilevel select" do
        let(:pattern) { "Ice Cream: $Q4" }

        it "uses the top level subquestion" do
          is_expected.to eq(%(Ice Cream: <output value="jr:itext(coalesce(#{q4apath},&#39;BLANK&#39;))" />))
        end
      end
    end
  end

  describe "calc()" do
    let(:form) { create(:form, question_types: %w[integer integer]) }
    let(:q1) { ODK::QingDecorator.decorate(form.c[0]) }
    let(:q1path) { "/data/#{q1.odk_code}" }

    before do
      q1.update!(code: "Q1")
    end

    context "with simple expression" do
      let(:pattern) { "calc($Q1 + 2)" }
      it { is_expected.to eq(%(<output value="(#{q1path}) + 2" />)) }
    end

    context "with quoted string containing $" do
      let(:pattern) { "calc(myfunc((5 + 12) div $Q1, ' (($money cash'))" }
      it do
        is_expected.to eq(%{<output value="myfunc((5 + 12) div (#{q1path}), &#39; (($money cash&#39;)" />})
      end
    end

    context "with invalid code" do
      let(:pattern) { "calc($Junk + 7)" }
      it { is_expected.to eq(%(<output value="(&#39;&#39;) + 7" />)) }
    end

    context "with single and double quotes in pattern" do
      let(:pattern) { %{calc(myfunc($Q1,'"foo’s"'))} }
      it { is_expected.to eq(%(<output value="myfunc((#{q1path}),&#39;&quot;foo’s&quot;&#39;)" />)) }
    end
  end
end
