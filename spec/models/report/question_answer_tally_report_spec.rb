require 'spec_helper'

describe Report::QuestionAnswerTallyReport do

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
      @report = create(:question_answer_tally_report, _calculations: [@form.questions[0]])
    end

    it_behaves_like 'basic stuff'
  end

  context 'with option sets' do
    before do
      @option_set1 = create(:option_set)
      @option_set2 = create(:option_set)
      @report = create(:question_answer_tally_report, option_sets: [@option_set1, @option_set2])
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
end
