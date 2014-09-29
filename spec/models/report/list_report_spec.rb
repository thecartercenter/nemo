require 'spec_helper'

describe Report::ListReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
      @response = create(:response, form: @form, answer_values: [['Animal', 'Cat']])
      @report = create(:list_report, _calculations: [@form.questions[0]])
    end

    it 'should have answer values in correct order' do
      expect(@report).to have_legacy_report_data([@form.questions[0].name], ["Animal, Cat"])
    end
  end
end
