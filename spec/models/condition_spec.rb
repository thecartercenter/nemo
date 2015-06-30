require 'spec_helper'

describe Condition do
  before(:all) do
    I18n.locale = :en
  end

  describe 'options' do
    it 'should return nil if no option ids' do
      c = Condition.new(option_ids: nil)
      expect(c.options).to be_nil
    end

    context 'with multiple options' do
      before do
        @o1, @o2, @o3 = double(id: 15), double(id: 20), double(id: 25)
        allow(Option).to receive(:find).and_return([@o1, @o2, @o3])
      end

      it 'should return options in correct order' do
        c = Condition.new(option_ids: [20, 15, 25])
        expect(c.options).to eq [@o2, @o1, @o3]
      end
    end
  end

  describe 'any_fields_empty?' do
    before do
      @form = create(:form, question_types: %w(select_one integer))
    end

    it 'should be true if missing ref_qing' do
      @condition = Condition.new(ref_qing: nil, op: 'eq', option_ids: '[1]')
      expect(@condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing operator' do
      @condition = Condition.new(ref_qing: @form.questionings[0], op: nil, option_ids: [@form.questionings[0].options.first])
      expect(@condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing options' do
      @condition = Condition.new(ref_qing: @form.questionings[0], op: 'eq', option_ids: nil)
      expect(@condition.send(:any_fields_empty?)).to be true
    end

    it 'should be true if missing value' do
      @condition = Condition.new(ref_qing: @form.questionings[1], op: 'eq', value: nil)
      expect(@condition.send(:any_fields_empty?)).to be true
    end

    it 'should be false if options given' do
      @condition = Condition.new(ref_qing: @form.questionings[0], op: 'eq', option_ids: [@form.questionings[0].options.first])
      expect(@condition.send(:any_fields_empty?)).to be false
    end

    it 'should be false if value given' do
      @condition = Condition.new(ref_qing: @form.questionings[1], op: 'eq', value: '5')
      expect(@condition.send(:any_fields_empty?)).to be false
    end
  end

  describe 'to_odk' do
    # q, c = build_condition
    # assert_equal("/data/q#{q.previous[0].question.id} = #{c.value}", c.to_odk)
    # q, c = build_condition(:question_types => %w(select_one integer))
    # assert_equal("selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}')", c.to_odk)
    # q, c = build_condition(:question_types => %w(select_one integer), :op => 'neq')
    # assert_equal("not(selected(/data/q#{q.previous[0].question.id}, '#{c.option_id}'))", c.to_odk)
    # q, c = build_condition(:question_types => %w(datetime integer), :op => 'neq', :value => '2013-04-30 2:14pm')
    # assert_equal("format-date(/data/q#{q.previous[0].question.id}, '%Y%m%d%H%M') != '201304301414'", c.to_odk)

    context 'for single level select one question' do
      before do
        @form = create(:form, question_types: %w(select_one))
        @qing = @form.questionings.first
        @option = @qing.options.first
        @option_node = @option.option_nodes.where(option_set_id: @qing.option_set).first
      end

      it 'should work with eq operator' do
        c = Condition.new(ref_qing: @qing, op: 'eq', option_ids: [@option.id])
        expect(c.to_odk).to eq "selected(/data/#{@qing.odk_code}, 'on#{@option_node.id}')"
      end

      it 'should work with neq operator' do
        c = Condition.new(ref_qing: @qing, op: 'neq', option_ids: [@option.id])
        expect(c.to_odk).to eq "not(selected(/data/#{@qing.odk_code}, 'on#{@option_node.id}'))"
      end
    end

    context 'for multilevel select one question' do
      before do
        @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
        @qing = @form.questionings[0]
        @oset = @qing.option_set
      end

      it 'should work for first level' do
        c = Condition.new(ref_qing: @qing, op: 'eq', option_ids: [@oset.c[0].option_id])
        expect(c.to_odk).to eq "selected(/data/#{@qing.subquestions[0].odk_code}, 'on#{@oset.c[0].id}')"
      end

      it 'should work for second level' do
        c = Condition.new(ref_qing: @qing, op: 'eq', option_ids: [@oset.c[0].option_id, @oset.c[0].c[1].option_id])
        expect(c.to_odk).to eq "selected(/data/#{@qing.subquestions[1].odk_code}, 'on#{@oset.c[0].c[1].id}')"
      end
    end

    context 'for select multiple question' do
      before do
        @form = create(:form, question_types: %w(select_multiple))
        @qing = @form.questionings[0]
        @options = @qing.options
        @option_nodes = OptionNode.where(option_id: @options.map(&:id), option_set_id: @qing.option_set).sort_by do |on|
          @options.index { |o| o.id == on.option_id }
        end
      end

      it 'should work with inc operator' do
        c = Condition.new(ref_qing: @qing, op: 'inc', option_ids: [@options[0].id])
        expect(c.to_odk).to eq "selected(/data/#{@qing.odk_code}, 'on#{@option_nodes[0].id}')"
      end

      it 'should work with ninc operator' do
        c = Condition.new(ref_qing: @qing, op: 'ninc', option_ids: [@options[1].id])
        expect(c.to_odk).to eq "not(selected(/data/#{@qing.odk_code}, 'on#{@option_nodes[1].id}'))"
      end
    end

    context 'for non-select question' do
      before do
        @form = create(:form, question_types: %w(integer text date time datetime))
        @int_q, @text_q, @date_q, @time_q, @datetime_q = @form.questionings
      end

      it 'should work with eq operator and int question' do
        c = Condition.new(ref_qing: @int_q, op: 'eq', value: '5')
        expect(c.to_odk).to eq "/data/#{@int_q.odk_code} = 5"
      end

      it 'should work with neq operator and text question' do
        c = Condition.new(ref_qing: @text_q, op: 'neq', value: 'foo')
        expect(c.to_odk).to eq "/data/#{@text_q.odk_code} != 'foo'"
      end

      it 'should work with date question and geq operator' do
        c = Condition.new(ref_qing: @date_q, op: 'geq', value: '1981-10-26')
        expect(c.to_odk).to eq "format-date(/data/#{@date_q.odk_code}, '%Y%m%d') >= '19811026'"
      end

      it 'should work with time question and leq operator' do
        c = Condition.new(ref_qing: @time_q, op: 'leq', value: '3:56pm')
        expect(c.to_odk).to eq "format-date(/data/#{@time_q.odk_code}, '%H%M') <= '1556'"
      end

      it 'should work with datetime question and gt operator' do
        c = Condition.new(ref_qing: @datetime_q, op: 'gt', value: 'Dec 3 2003 11:56')
        expect(c.to_odk).to eq "format-date(/data/#{@datetime_q.odk_code}, '%Y%m%d%H%M') > '200312031156'"
      end
    end
  end

  describe 'to_s' do
    context 'for numeric ref question' do
      before do
        @form = create(:form, question_types: %w(integer))
        @int_q = @form.questionings.first
        @cond = Condition.new(ref_qing: @int_q, op: 'lt', value: '5')
      end

      it 'should work' do
        expect(@cond.to_s).to eq "Question #1 is less than 5"
      end

      it 'should work when including code' do
        expect(@cond.to_s(include_code: true)).to eq "Question #1 #{@int_q.code} is less than 5"
      end
    end

    context 'for non-numeric ref question' do
      before do
        @form = create(:form, question_types: %w(text))
        @text_q = @form.questionings.first
        @cond = Condition.new(ref_qing: @text_q, op: 'eq', value: 'foo')
      end

      it 'should work' do
        expect(@cond.to_s).to eq "Question #1 is equal to \"foo\""
      end
    end

    context 'for multiselect ref question' do
      before do
        @form = create(:form, question_types: %w(select_multiple))
        @sel_q = @form.questionings.first
      end

      it 'positive should work' do
        c = Condition.new(ref_qing: @sel_q, op: 'inc', option_ids: [@sel_q.options.last.id])
        expect(c.to_s).to eq "Question #1 includes \"Dog\""
      end

      it 'negation should work' do
        c = Condition.new(ref_qing: @sel_q, op: 'ninc', option_ids: [@sel_q.options.last.id])
        expect(c.to_s).to eq "Question #1 does not include \"Dog\""
      end
    end

    context 'for single level select ref question' do
      before do
        @form = create(:form, question_types: %w(select_one))
        @sel_q = @form.questionings.first
      end

      it 'should work' do
        c = Condition.new(ref_qing: @sel_q, op: 'eq', option_ids: [@sel_q.options.last.id])
        expect(c.to_s).to eq "Question #1 is equal to \"Dog\""
      end
    end

    context 'for multi level select ref question' do
      before do
        @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
        @sel_q = @form.questionings.first
      end

      it 'matching first level should work' do
        c = Condition.new(ref_qing: @sel_q, op: 'eq', option_ids: [@sel_q.option_set.c[0].option_id])
        expect(c.to_s).to eq "Question #1 Kingdom is equal to \"Animal\""
      end

      context 'matching second level' do
        before do
          @cond = Condition.new(ref_qing: @sel_q, op: 'eq',
            option_ids: [@sel_q.option_set.c[1].option_id, @sel_q.option_set.c[1].c[0].option_id])
        end

        it 'should work normally' do
          expect(@cond.to_s).to eq "Question #1 Species is equal to \"Tulip\""
        end

        it 'should work when including code' do
          expect(@cond.to_s(include_code: true)).to eq "Question #1 #{@sel_q.code} Species is equal to \"Tulip\""
        end
      end
    end
  end

  describe 'clear blanks' do
    before do
      @cond = Condition.new(op: 'eq', value: '  ', option_ids: '')
      @cond.valid?
    end

    it 'should clear blanks' do
      expect(@cond.value).to be_nil
      expect(@cond.option_ids).to be_nil
    end
  end

  describe 'clean times' do
    before do
      @form = create(:form, question_types: %w(datetime integer))
      @cond = Condition.new(ref_qing: @form.questionings[0], value: '2013-04-30 2:14pm')
      @cond.valid?
    end

    it 'should clean time' do
      expect(@cond.value).to eq '2013-04-30 14:14'
    end
  end

  describe 'refable qings' do
    before do
      @form = create(:form, question_types: %w(location integer integer integer integer))
      @cond = Condition.new(questioning: @form.questionings[3])
    end

    it 'should be correct' do
      expect(@cond.refable_qings).to eq @form.questionings[1..2]
    end
  end

  describe 'applicable operator names' do
    before do
      @form = create(:form, question_types: %w(select_one integer))
      @cond = Condition.new(ref_qing: @form.questionings[0])
    end

    it 'should be correct' do
      expect(@cond.applicable_operator_names).to eq %w(eq neq)
    end
  end

  describe 'verify ordering' do
    before do
      @form = create(:form, question_types: %w(integer integer))
      @qings = @form.questionings
    end

    it 'should raise error when qing comes before ref_qing' do
      @cond = create(:condition, questioning: @form.questionings[1], ref_qing: @form.questionings[0])
      expect{@cond.verify_ordering(@qings[0].id => 2, @qings[1].id => 1)}.to raise_error(ConditionOrderingError)
    end

    it 'should not raise error if ordering is correct' do
      @cond = create(:condition, questioning: @form.questionings[1], ref_qing: @form.questionings[0])
      expect{@cond.verify_ordering(@qings[0].id => 1, @qings[1].id => 2)}.not_to raise_error
    end
  end
end
