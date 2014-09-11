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
end
