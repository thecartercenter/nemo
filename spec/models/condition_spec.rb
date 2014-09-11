require 'spec_helper'

describe Condition do
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
end
