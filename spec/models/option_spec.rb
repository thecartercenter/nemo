require 'spec_helper'

describe Option do

  it 'should create cleanly' do
    create(:option, :name => 'Foo')
  end

  it 'should prohibit too-long names' do
    (option = build(:option, :name => 'Foooooooooo oooo oooooooooooo oooooooooooooooo')).save
    assert_match(/characters in length/, option.errors.messages[:base].join)
  end

  it 'should require at least one name translation' do
    (option = build(:option, :name => '')).save
    assert_match(/At least one name translation/, option.errors.messages[:base].join)
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
end
