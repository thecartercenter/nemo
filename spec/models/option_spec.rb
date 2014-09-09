require 'spec_helper'

describe Option do

  it 'should create cleanly' do
    create(:option, :name => 'Foo')
  end

  describe 'suggestions' do

    shared_examples 'return matches' do
      it 'should return two matches' do
        expect(@suggestions.size).to eq 2
        expect(@suggestions[0].name).to eq 'Foo'
        expect(@suggestions[1].name).to eq 'f' # Placeholder for creating new option
      end
    end

    context 'for nil mission' do
      before do
        create(:option, :is_standard => true, :name => 'Foo')
        @suggestions = Option.suggestions(nil, 'f')
      end

      it_should_behave_like 'return matches'
    end

    context 'for non-nil mission' do
      before do
        create(:option, :name => 'Foo')
        @suggestions = Option.suggestions(get_mission, 'f')
      end

      it_should_behave_like 'return matches'
    end
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
