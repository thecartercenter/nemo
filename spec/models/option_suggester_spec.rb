require 'spec_helper'

describe OptionSuggester do

  context 'general case' do
    before do
      ['Bar', "Foo's Bar", 'Foo'].each{ |n| create(:option, name: n) }
    end

    it 'should return exact match at top with no placeholder' do
      result = OptionSuggester.new.suggest(get_mission, 'foo')
      expect(result.map(&:name)).to eq ['Foo', "Foo's Bar"]
    end

    it 'should return non-exact matches sorted with a placeholder at bottom' do
      result = OptionSuggester.new.suggest(get_mission, 'fo')
      expect(result.map(&:name)).to eq ['Foo', "Foo's Bar", 'fo']
    end

    it 'should return just placeholder if no matches' do
      # Should not match since we match only from start of string.
      result = OptionSuggester.new.suggest(get_mission, 'oo')
      expect(result.map(&:name)).to eq ['oo']
    end
  end

  describe 'mission scoping' do
    shared_examples 'return matches' do
      it 'should return two matches' do
        expect(@suggestions.size).to eq 2
        expect(@suggestions[0].name).to eq 'Foo'
        expect(@suggestions[1].name).to eq 'f' # Placeholder for creating new option
      end
    end

    context 'when multiple missions' do
      before do
        @missions = create_list(:mission, 2)
        @missions.each{ |m| create(:option, name: 'Foo', mission: m) }
        @suggestions = OptionSuggester.new.suggest(@missions[0], 'f')
      end

      it_should_behave_like 'return matches'
    end

    context 'for nil mission' do
      before do
        create(:option, name: 'Foo', mission: nil)
        @suggestions = OptionSuggester.new.suggest(nil, 'f')
      end

      it_should_behave_like 'return matches'
    end

    context 'for regular mission' do
      before do
        create(:option, name: 'Foo')
        @suggestions = OptionSuggester.new.suggest(get_mission, 'f')
      end

      it_should_behave_like 'return matches'
    end
  end
end
