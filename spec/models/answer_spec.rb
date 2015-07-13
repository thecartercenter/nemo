require 'spec_helper'

describe Answer do
  context 'has_coordinates?' do
    context 'with a select_one question' do
      let(:form) { create(:form, question_types: %w(select_one)) }
      let(:questioning) { form.questionings.first }
      let(:option) { questioning.options.first }

      it 'should return false if the selected option does not have coordinates' do
        answer = create(:answer, option: option, questioning: questioning)
        expect(answer.has_coordinates?).to be_falsy
      end

      it 'should return true if the selected option has coordinates' do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option.update_attributes(latitude: 0, longitude: 0)

        answer = create(:answer, option: option, questioning: questioning)
        expect(answer.has_coordinates?).to be_truthy
      end
    end

    context 'with a select_multiple question' do
      let(:form) { create(:form, question_types: %w(select_multiple)) }
      let(:questioning) { form.questionings.first }
      let(:option_one) { questioning.options.first }
      let(:option_two) { questioning.options.second }

      it 'should return false if no options were selected' do
        answer = create(:answer, questioning: questioning)
        expect(answer.has_coordinates?).to be_falsy
      end

      it 'should return false if the selected options do not have coordinates' do
        answer = create(:answer, questioning: questioning)
        create(:choice, answer: answer, option: option_one)
        create(:choice, answer: answer, option: option_two)
        answer.reload

        expect(answer.has_coordinates?).to be_falsy
      end

      it 'should return true if all of the selected options have coordinates' do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option_one.update_attributes(latitude: 0, longitude: 0)
        option_two.update_attributes(latitude: 0, longitude: 0)

        answer = create(:answer, questioning: questioning)
        create(:choice, answer: answer, option: option_one)
        create(:choice, answer: answer, option: option_two)
        answer.reload

        expect(answer.has_coordinates?).to be_truthy
      end

      it 'should return true if any of the selected options have coordinates' do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option_one.update_attributes(latitude: 0, longitude: 0)

        answer = create(:answer, questioning: questioning)
        create(:choice, answer: answer, option: option_one)
        create(:choice, answer: answer, option: option_two)
        answer.reload

        expect(answer.has_coordinates?).to be_truthy
      end
    end
  end
end
