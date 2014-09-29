require 'spec_helper'

describe Report::GroupedTallyReport do
  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
      create(:response, form: @form, answer_values: [['Animal', 'Cat']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal', 'Dog']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal']], source: 'odk')
      create(:response, form: @form, answer_values: [['Plant', 'Oak']], source: 'odk')
      @report = create(:grouped_tally_report, _calculations: [@form.questions[0], 'source'])
    end

    it 'should count only top-level answers' do
      expect(@report).to have_legacy_report_data(
        %w(       odk web TTL),
        %w(Animal   1   2   3),
        %w(Plant    1   _   1),
        %w(TTL      2   2   4)
      )
    end
  end
end