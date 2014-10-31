require 'spec_helper'

describe Option do

  it 'should create cleanly' do
    create(:option, :name => 'Foo')
  end

  describe 'recent changes' do
    before { @option = create(:option, name: 'Foo') }

    context 'without flag set' do
      before do
        @option.update_attributes!(name: 'Bar')
      end

      it 'should have no recent changes' do
        expect(@option.recent_changes).to be_nil
      end
    end

    context 'with flag set' do
      before do
        allow(@option).to receive(:capturing_changes?).and_return(true)
        @option.update_attributes!(name: 'Baz')
      end

      it 'should have an entry for name_translations' do
        expect(@option.recent_change_for('name_translations')).to eq [{"en"=>"Foo"}, {"en"=>"Baz"}]
      end
    end
  end
end
