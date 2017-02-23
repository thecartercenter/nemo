require 'spec_helper'

describe Condition do
  before(:all) do
    I18n.locale = :en
  end

  describe 'any_fields_empty?' do
    let(:form) { create(:form, question_types: %w(select_one integer)) }
    let(:option_node_id) { form.questionings[0].option_set.children.first.id }

    it 'should be true if missing ref_qing' do
      condition = Condition.new(ref_qing: nil, op: 'eq', option_node_id: option_node_id)
      expect(condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing operator' do
      condition = Condition.new(ref_qing: form.questionings[0], op: nil, option_node_id: option_node_id)
      expect(condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing option node' do
      condition = Condition.new(ref_qing: form.questionings[0], op: 'eq', option_node_id: nil)
      expect(condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing value' do
      condition = Condition.new(ref_qing: form.questionings[1], op: 'eq', value: nil)
      expect(condition.send(:any_fields_empty?)).to be true
    end

    it 'should be false if option node given' do
      condition = Condition.new(ref_qing: form.questionings[0], op: 'eq', option_node_id: option_node_id)
      expect(condition.send(:any_fields_empty?)).to be false
    end

    it 'should be false if value given' do
      condition = Condition.new(ref_qing: form.questionings[1], op: 'eq', value: '5')
      expect(condition.send(:any_fields_empty?)).to be false
    end
  end

  describe 'to_odk' do
    # q, c = build_condition
    # expect(c.to_odk).to eq("/data/q#{q.previous[0].question.id} = #{c.value}")
    # q, c = build_condition(:question_types => %w(select_one integer))
    # expect(c.to_odk).to eq("selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}')")
    # q, c = build_condition(:question_types => %w(select_one integer), :op => 'neq')
    # expect(c.to_odk).to eq("not(selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}'))")
    # q, c = build_condition(:question_types => %w(datetime integer), :op => 'neq', :value => '2013-04-30 2:14pm')
    # expect(c.to_odk).to eq("format-date(/data/q#{q.previous[0].question.id}, '%Y%m%d%H%M') != '201304301414'")
    let(:qing) { form.questionings.first }
    let(:opt_set) { qing.option_set }
    let(:option_node) { qing.option_set.c[0] }

    context 'for single level select one question' do
      let(:form) { create(:form, question_types: %w(select_one)) }

      it 'should work with eq operator' do
        c = Condition.new(ref_qing: qing, op: 'eq', option_node: option_node)
        expect(c.to_odk).to eq "selected(/data/#{qing.odk_code}, 'on#{option_node.id}')"
      end

      it 'should work with neq operator' do
        c = Condition.new(ref_qing: qing, op: 'neq', option_node: option_node)
        expect(c.to_odk).to eq "not(selected(/data/#{qing.odk_code}, 'on#{option_node.id}'))"
      end
    end

    context 'for multilevel select one question' do
      let(:form) { create(:form, question_types: %w(multilevel_select_one)) }

      it 'should work for first level' do
        c = Condition.new(ref_qing: qing, op: 'eq', option_node: opt_set.c[0])
        expect(c.to_odk).to eq "selected(/data/#{qing.subquestions[0].odk_code}, 'on#{opt_set.c[0].id}')"
      end

      it 'should work for second level' do
        c = Condition.new(ref_qing: qing, op: 'eq', option_node: opt_set.c[0].c[1])
        expect(c.to_odk).to eq "selected(/data/#{qing.subquestions[1].odk_code}, 'on#{opt_set.c[0].c[1].id}')"
      end
    end

    context 'for select multiple question' do
      let(:form) { create(:form, question_types: %w(select_multiple)) }

      it 'should work with inc operator' do
        c = Condition.new(ref_qing: qing, op: 'inc', option_node: option_node)
        expect(c.to_odk).to eq "selected(/data/#{qing.odk_code}, 'on#{option_node.id}')"
      end

      it 'should work with ninc operator' do
        c = Condition.new(ref_qing: qing, op: 'ninc', option_node: option_node)
        expect(c.to_odk).to eq "not(selected(/data/#{qing.odk_code}, 'on#{option_node.id}'))"
      end
    end

    context 'for non-select question' do
      let(:form) { form = create(:form, question_types: %w(integer text date time datetime)) }
      let(:int_q) { form.questionings[0] }
      let(:text_q) { form.questionings[1] }
      let(:date_q) { form.questionings[2] }
      let(:time_q) { form.questionings[3] }
      let(:datetime_q) { form.questionings[4] }

      it 'should work with eq operator and int question' do
        c = Condition.new(ref_qing: int_q, op: 'eq', value: '5')
        expect(c.to_odk).to eq "/data/#{int_q.odk_code} = 5"
      end

      it 'should work with neq operator and text question' do
        c = Condition.new(ref_qing: text_q, op: 'neq', value: 'foo')
        expect(c.to_odk).to eq "/data/#{text_q.odk_code} != 'foo'"
      end

      it 'should work with date question and geq operator' do
        c = Condition.new(ref_qing: date_q, op: 'geq', value: '1981-10-26')
        expect(c.to_odk).to eq "format-date(/data/#{date_q.odk_code}, '%Y%m%d') >= '19811026'"
      end

      it 'should work with time question and leq operator' do
        c = Condition.new(ref_qing: time_q, op: 'leq', value: '3:56pm')
        expect(c.to_odk).to eq "format-date(/data/#{time_q.odk_code}, '%H%M') <= '1556'"
      end

      it 'should work with datetime question and gt operator' do
        c = Condition.new(ref_qing: datetime_q, op: 'gt', value: 'Dec 3 2003 11:56')
        expect(c.to_odk).to eq "format-date(/data/#{datetime_q.odk_code}, '%Y%m%d%H%M') > '200312031156'"
      end
    end
  end

  describe 'to_s' do
    context 'for numeric ref question' do
      let(:form) { create(:form, question_types: %w(integer)) }
      let(:int_q) { form.questionings.first }
      let(:cond) { Condition.new(ref_qing: int_q, op: 'lt', value: '5') }

      it 'should work' do
        expect(cond.to_s).to eq "Question #1 is less than 5"
      end

      it 'should work when including code' do
        expect(cond.to_s(include_code: true)).to eq "Question #1 #{int_q.code} is less than 5"
      end
    end

    context 'for non-numeric ref question' do
      let(:form) { create(:form, question_types: %w(text)) }
      let(:text_q) { form.questionings.first }
      let(:cond) { Condition.new(ref_qing: text_q, op: 'eq', value: 'foo') }

      it 'should work' do
        expect(cond.to_s).to eq "Question #1 is equal to \"foo\""
      end
    end

    context 'for multiselect ref question' do
      let(:form) { create(:form, question_types: %w(select_multiple)) }
      let(:sel_q) { form.questionings.first }

      it 'positive should work' do
        c = Condition.new(ref_qing: sel_q, op: 'inc', option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 includes \"Dog\""
      end

      it 'negation should work' do
        c = Condition.new(ref_qing: sel_q, op: 'ninc', option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 does not include \"Dog\""
      end
    end

    context 'for single level select ref question' do
      let(:form) { create(:form, question_types: %w(select_one)) }
      let(:sel_q) { form.questionings.first }

      it 'should work' do
        c = Condition.new(ref_qing: sel_q, op: 'eq', option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 is equal to \"Dog\""
      end
    end

    context 'for multi level select ref question' do
      let(:form) { create(:form, question_types: %w(multilevel_select_one)) }
      let(:sel_q) { form.questionings.first }

      it 'matching first level should work' do
        c = Condition.new(ref_qing: sel_q, op: 'eq', option_node: sel_q.option_set.c[0])
        expect(c.to_s).to eq "Question #1 Kingdom is equal to \"Animal\""
      end

      context 'matching second level' do
        let(:cond) { Condition.new(ref_qing: sel_q, op: 'eq', option_node: sel_q.option_set.c[1].c[0]) }

        it 'should work normally' do
          expect(cond.to_s).to eq "Question #1 Species is equal to \"Tulip\""
        end

        it 'should work when including code' do
          expect(cond.to_s(include_code: true)).to eq "Question #1 #{sel_q.code} Species is equal to \"Tulip\""
        end
      end
    end
  end

  describe 'clear blanks' do
    let(:cond) { Condition.new(op: 'eq', value: '  ', option_ids: '') }

    it 'should clear blanks' do
      cond.valid?
      expect(cond.value).to be_nil
      expect(cond.option_ids).to be_nil
    end
  end

  describe 'clean times' do
    let(:form) { create(:form, question_types: %w(datetime integer)) }
    let(:cond) { Condition.new(ref_qing: form.questionings[0], value: '2013-04-30 2:14pm') }

    it 'should clean time' do
      cond.valid?
      expect(cond.value).to eq '2013-04-30 14:14'
    end
  end

  describe 'refable qings' do
    let(:form) { create(:form, question_types: %w(location integer integer integer integer)) }
    let(:cond) { Condition.new(questioning: form.questionings[3]) }

    it 'should be correct' do
      expect(cond.refable_qings).to eq form.questionings[1..2]
    end
  end

  describe 'applicable operator names' do
    let(:form) { create(:form, question_types: %w(select_one integer)) }
    let(:cond) { Condition.new(ref_qing: form.questionings[0]) }

    it 'should be correct' do
      expect(cond.applicable_operator_names).to eq %w(eq neq)
    end
  end
end
