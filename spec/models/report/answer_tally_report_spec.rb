# There are more report tests in test/unit/report.
require 'spec_helper'

describe Report::AnswerTallyReport do

  shared_examples_for 'basic stuff' do
    describe 'destroy' do
      before do
        # Reloading here was the only way to reproduce a stack level too deep bug.
        @report.reload
        @report.destroy
      end

      it 'should work' do
        expect(@report).to be_destroyed
      end
    end
  end

  context 'with specific questions' do
    before do
      @form = create(:form, question_types: %w(select_one))
      @report = create(:answer_tally_report, _calculations: [@form.questions[0]])
    end

    it_behaves_like 'basic stuff'
  end

  context 'with option sets' do
    before do
      @option_set1 = create(:option_set)
      @option_set2 = create(:option_set)
      @report = create(:answer_tally_report, option_sets: [@option_set1, @option_set2])
    end

    it_behaves_like 'basic stuff'

    context 'when related option set destroyed' do
      before do
        @option_set1.destroy
      end

      it 'should not be destroyed but should no longer reference the destroyed set' do
        expect(Report::Report.exists?(@report)).to be true
        expect(@report.reload.option_sets).to eq [@option_set2]
      end
    end

    context 'when last related option set destroyed' do
      before do
        @option_set1.destroy
        @option_set2.destroy
      end

      it 'should destroy self' do
        expect(Report::Report.exists?(@report)).to be false
      end
    end
  end

  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(select_one), use_multilevel_option_set: true)
      create(:response, form: @form, answer_values: [['Animal', 'Cat']])
      create(:response, form: @form, answer_values: [['Animal', 'Dog']])
      create(:response, form: @form, answer_values: [['Animal']])
      create(:response, form: @form, answer_values: [['Plant', 'Oak']])
      @report = create(:answer_tally_report, option_sets: [@form.questions[0].option_set])
    end

    it 'should count only top-level answers' do
      expect(@report).to have_data_grid(
                                    %w(    Animal Plant TTL),
        [@form.questions[0].name] + %w(    3      1     4),
                                    %w(TTL 3      1     4)
      )
    end
  end
end
