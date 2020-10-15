# frozen_string_literal: true

require "rails_helper"

describe ODK::ConditionDecorator do
  include_context "odk rendering"

  describe "to_odk", :odk do
    let(:q1) { decorate(form.c[0]) }
    let(:opt_set) { form.c[0].option_set }
    let(:hostq) { decorate(form.c.last) }
    let(:condition) { Condition.new({conditionable: hostq.object}.merge(params)) }
    subject(:xpath) { decorate(condition).to_odk }

    context "when right_side_type is literal" do
      context "for single level select one question" do
        let(:form) { create(:form, question_types: %w[select_one text]) }

        context "with eq operator" do
          let(:params) { {left_qing: q1.object, op: "eq", option_node: opt_set.c[0]} }
          it { is_expected.to eq("/data/#{q1.odk_code} = '#{opt_set.c[0].odk_code}'") }
        end

        context "with neq operator" do
          let(:params) { {left_qing: q1.object, op: "neq", option_node: opt_set.c[0]} }
          it { is_expected.to eq("/data/#{q1.odk_code} != '#{opt_set.c[0].odk_code}'") }
        end
      end

      context "for multilevel select one question" do
        let(:form) { create(:form, question_types: %w[multilevel_select_one]) }
        let(:subq1) { decorate(q1.subqings[0]) }
        let(:subq2) { decorate(q1.subqings[1]) }

        context "for first level" do
          let(:params) { {left_qing: q1.object, op: "eq", option_node: opt_set.c[0]} }
          it { is_expected.to eq("/data/#{subq1.odk_code} = '#{opt_set.c[0].odk_code}'") }
        end

        context "for second level" do
          let(:params) { {left_qing: q1.object, op: "eq", option_node: opt_set.c[0].c[1]} }
          it { is_expected.to eq("/data/#{subq2.odk_code} = '#{opt_set.c[0].c[1].odk_code}'") }
        end
      end

      context "for select multiple question" do
        let(:form) { create(:form, question_types: %w[select_multiple text]) }

        context "with inc operator" do
          let(:params) { {left_qing: q1.object, op: "inc", option_node: opt_set.c[0]} }
          it { is_expected.to eq("selected(/data/#{q1.odk_code}, '#{opt_set.c[0].odk_code}')") }
        end

        context "with ninc operator" do
          let(:params) { {left_qing: q1.object, op: "ninc", option_node: opt_set.c[0]} }
          it { is_expected.to eq("not(selected(/data/#{q1.odk_code}, '#{opt_set.c[0].odk_code}'))") }
        end
      end

      context "for non-select question" do
        let(:form) { create(:form, question_types: %w[integer text date time datetime text]) }
        let(:int_q) { decorate(form.c[0]) }
        let(:text_q) { decorate(form.c[1]) }
        let(:date_q) { decorate(form.c[2]) }
        let(:time_q) { decorate(form.c[3]) }
        let(:datetime_q) { decorate(form.c[4]) }

        context "with eq operator and int question" do
          let(:params) { {left_qing: int_q.object, op: "eq", value: "5"} }
          it { is_expected.to eq("/data/#{int_q.odk_code} = 5") }
        end

        context "with neq operator and text question" do
          let(:params) { {left_qing: text_q.object, op: "neq", value: "foo"} }
          it { is_expected.to eq("/data/#{text_q.odk_code} != 'foo'") }
        end

        context "with date question and geq operator" do
          let(:params) { {left_qing: date_q.object, op: "geq", value: "1981-10-26"} }
          it { is_expected.to eq("format-date(/data/#{date_q.odk_code}, '%Y%m%d') >= '19811026'") }
        end

        context "with time question and leq operator" do
          let(:params) { {left_qing: time_q.object, op: "leq", value: "3:56pm"} }
          it { is_expected.to eq("format-date(/data/#{time_q.odk_code}, '%H%M') <= '1556'") }
        end

        context "with datetime question and gt operator" do
          let(:params) { {left_qing: datetime_q.object, op: "gt", value: "Dec 3 2003 11:56"} }
          it { is_expected.to eq("format-date(/data/#{datetime_q.odk_code}, '%Y%m%d%H%M') > '200312031156'") }
        end
      end

      context "for intra-group reference" do
        let(:form) { create(:form, question_types: [%w[multilevel_select_one text text]]) }
        let(:q1) { decorate(form.c[0].c[0]) }
        let(:q2) { decorate(form.c[0].c[1]) }

        context "for regular ref qing" do
          let(:params) { {left_qing: q2.object, op: "eq", value: "foo"} }
          it { is_expected.to eq("../#{q2.odk_code} = 'foo'") }
        end

        context "for multilevel ref qing" do
          let(:opt_set) { q1.option_set }
          let(:params) { {left_qing: q1.object, op: "eq", option_node: opt_set.c[0].c[0]} }
          it { is_expected.to eq("../#{q1.odk_code}_2 = '#{opt_set.c[0].c[0].odk_code}'") }
        end
      end
    end

    context "when right_side_type is qing" do
      let(:q2) { decorate(form.c[1]) }

      context "with straight equality" do
        let(:form) { create(:form, question_types: %w[text text]) }
        let(:params) { {left_qing: q2.object, op: "eq", right_qing: q1.object} }
        it { is_expected.to eq(". = /data/#{q1.odk_code}") }
      end

      context "with temporal questions" do
        let(:form) { create(:form, question_types: %w[date date]) }
        let(:params) { {left_qing: q2.object, op: "eq", right_qing: q1.object} }
        it { is_expected.to eq(". = /data/#{q1.odk_code}") }
      end

      context "with intra group references" do
        let(:form) { create(:form, question_types: [%w[integer integer]]) }
        let(:q1) { decorate(form.c[0].c[0]) }
        let(:q2) { decorate(form.c[0].c[1]) }
        let(:params) { {left_qing: q2.object, op: "gt", right_qing: q1.object} }
        it { is_expected.to eq("../#{q2.odk_code} > ../#{q1.odk_code}") }
      end

      context "with multilevel questions" do
        let(:form) { create(:form, question_types: %w[multilevel_select_one super_multilevel_select_one]) }
        let(:params) { {left_qing: q2.object, op: "eq", right_qing: q1.object} }
        let(:xp1_1) { "/data/#{decorate(q1.subqings[0]).odk_code}" }
        let(:xp1_2) { "/data/#{decorate(q1.subqings[1]).odk_code}" }
        let(:xp2_1) { "/data/#{decorate(q2.subqings[0]).odk_code}" }
        let(:xp2_2) { "/data/#{decorate(q2.subqings[1]).odk_code}" }
        let(:xp2_3) { "/data/#{decorate(q2.subqings[2]).odk_code}" }

        it "uses the lowest specified level for both" do
          is_expected.to eq("coalesce(coalesce(#{xp2_3}, #{xp2_2}), #{xp2_1}) = coalesce(#{xp1_2}, #{xp1_1})")
        end
      end
    end
  end
end
