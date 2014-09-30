# There are more report tests in test/unit/report.
require 'spec_helper'

describe Report::ResponseTallyReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
      create(:response, form: @form, answer_values: [['Animal', 'Cat']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal', 'Dog']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal']], source: 'odk')
      create(:response, form: @form, answer_values: [['Plant', 'Oak']], source: 'odk')
      @report = create(:response_tally_report, _calculations: [@form.questions[0], 'source'])
    end

    it 'should count only top-level answers' do
      expect(@report).to have_data_grid(
        %w(       odk web TTL),
        %w(Animal   1   2   3),
        %w(Plant    1   _   1),
        %w(TTL      2   2   4)
      )
    end
  end
end