require 'spec_helper'

describe Odk::ConditionDecorator do
  describe "to_odk", :odk do
    let(:qing) { Odk::DecoratorFactory.decorate(form.questionings.first) }
    let(:opt_set) { qing.option_set }
    let(:option_node) { qing.option_set.c[0] }
    let(:xpath) { Odk::DecoratorFactory.decorate(condition).to_odk }

    context "for single level select one question" do
      let(:form) { create(:form, question_types: %w(select_one)) }

      context "with eq operator" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "eq", option_node: option_node) }

        it do
          expect(xpath).to eq "selected(/data/#{qing.odk_code}, 'on#{option_node.id}')"
        end
      end

      context "with neq operator" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "neq", option_node: option_node) }

        it do
          expect(xpath).to eq "not(selected(/data/#{qing.odk_code}, 'on#{option_node.id}'))"
        end
      end
    end

    context "for multilevel select one question" do
      let(:form) { create(:form, question_types: %w(multilevel_select_one)) }

      context "for first level" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "eq", option_node: opt_set.c[0]) }

        it do
          expect(xpath).to eq "selected(/data/#{qing.subquestions[0].odk_code}, 'on#{opt_set.c[0].id}')"
        end
      end

      context "for second level" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "eq", option_node: opt_set.c[0].c[1]) }

        it do
          expect(xpath).to eq "selected(/data/#{qing.subquestions[1].odk_code}, 'on#{opt_set.c[0].c[1].id}')"
        end
      end
    end

    context "for select multiple question" do
      let(:form) { create(:form, question_types: %w(select_multiple)) }

      context "with inc operator" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "inc", option_node: option_node) }

        it do
          expect(xpath).to eq "selected(/data/#{qing.odk_code}, 'on#{option_node.id}')"
        end
      end

      context "with ninc operator" do
        let(:condition) { Condition.new(ref_qing: qing.object, op: "ninc", option_node: option_node) }

        it do
          expect(xpath).to eq "not(selected(/data/#{qing.odk_code}, 'on#{option_node.id}'))"
        end
      end
    end

    context "for non-select question" do
      let(:form) { form = create(:form, question_types: %w(integer text date time datetime)) }
      let(:int_q) { Odk::DecoratorFactory.decorate(form.questionings[0]) }
      let(:text_q) { Odk::DecoratorFactory.decorate(form.questionings[1]) }
      let(:date_q) { Odk::DecoratorFactory.decorate(form.questionings[2]) }
      let(:time_q) { Odk::DecoratorFactory.decorate( form.questionings[3]) }
      let(:datetime_q) { Odk::DecoratorFactory.decorate(form.questionings[4]) }

      context "with eq operator and int question" do
        let(:condition) { Condition.new(ref_qing: int_q.object, op: "eq", value: "5") }

        it do
          expect(xpath).to eq "/data/#{int_q.odk_code} = 5"
        end
      end

      context "with neq operator and text question" do
        let(:condition) { Condition.new(ref_qing: text_q.object, op: "neq", value: "foo") }

        it do
          expect(xpath).to eq "/data/#{text_q.odk_code} != 'foo'"
        end
      end

      context "with date question and geq operator" do
        let(:condition) { Condition.new(ref_qing: date_q.object, op: "geq", value: "1981-10-26") }

        it do
          expect(xpath).to eq "format-date(/data/#{date_q.odk_code}, '%Y%m%d') >= '19811026'"
        end
      end

      context "with time question and leq operator" do
        let(:condition) { Condition.new(ref_qing: time_q.object, op: "leq", value: "3:56pm") }

        it do
          expect(xpath).to eq "format-date(/data/#{time_q.odk_code}, '%H%M') <= '1556'"
        end
      end

      context "with datetime question and gt operator" do
        let(:condition) { Condition.new(ref_qing: datetime_q.object, op: "gt", value: "Dec 3 2003 11:56") }

        it do
          expect(xpath).to eq "format-date(/data/#{datetime_q.odk_code}, '%Y%m%d%H%M') > '200312031156'"
        end
      end
    end

    context "for intra-group reference" do
      let(:form) { create(:form, question_types: [["text", "text"]]) }
      let(:q1) { Odk::DecoratorFactory.decorate(form.sorted_children[0].sorted_children[0]) }
      let(:q2) { Odk::DecoratorFactory.decorate(form.sorted_children[0].sorted_children[1]) }

      let(:condition) { Condition.new(questioning: q2.object, ref_qing: q1.object, op: "eq", value: "foo") }

      it do
        expect(xpath).to eq "../#{q1.odk_code} = 'foo'"
      end
    end
  end
end
