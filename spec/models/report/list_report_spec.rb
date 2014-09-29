require 'spec_helper'

describe Report::ListReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one integer select_one), use_multilevel_option_set: true)
      @response = create(:response, form: @form, answer_values: [['Animal', 'Cat'], 5, ['Animal', 'Dog']])
      @response = create(:response, form: @form, answer_values: [['Animal'], 10, ['Plant', 'Oak']])
      @response = create(:response, form: @form, answer_values: [nil, 15, ['Plant']])
      @report = create(:list_report, _calculations: @form.questions + ['source'])
    end

    it 'should have answer values in correct order' do
      expect(@report).to have_legacy_report_data(
        @form.questions.map(&:name) + ['Source'],
        ['Animal, Cat', '5',  'Animal, Dog', 'web'],
        ['Animal',      '10', 'Plant, Oak',  'web'],
        ['_',           '15', 'Plant',       'web']
      )
    end
  end
end
