# There are more report tests in test/unit/report.
require 'spec_helper'

describe Report::ListReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one integer select_one), use_multilevel_option_set: true)
      @response1 = create(:response, form: @form, answer_values: [['Animal', 'Cat'], 5, ['Animal', 'Dog']])
      @response2 = create(:response, form: @form, answer_values: [['Animal'], 10, ['Plant', 'Oak']])
      @response3 = create(:response, form: @form, answer_values: [nil, 15, ['Plant']])
      @report = create(:list_report, _calculations: @form.questions + ['response_id'])
    end

    it 'should have answer values in correct order' do
      expect(@report).to have_data_grid(
        @form.questions.map(&:name) + ['Response ID'],
        ['Animal, Cat', '5',  'Animal, Dog', "##{@response1.id}"],
        ['Animal',      '10', 'Plant, Oak',  "##{@response2.id}"],
        ['_',           '15', 'Plant',       "##{@response3.id}"]
      )
    end
  end

  context 'with non-english locale' do
    before do
      I18n.locale = :fr
      @form = create(:form, question_types: %w(integer integer))
      @response = create(:response, form: @form, answer_values: [5, 10])
      @report = create(:list_report, _calculations: @form.questions + ['form'])
    end

    it 'should have proper headers' do
      expect(@form.questions[0].name_fr).to match(/Question/) # Ensure question created with french name.
      expect(@report).to have_data_grid(
        @form.questions.map(&:name_fr) + ['Fiche'],
        %w(5 10) + [@form.name]
      )
    end

    after do
      I18n.locale = :en
    end
  end
end
