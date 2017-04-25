require 'spec_helper'

describe Choice do
  it_behaves_like "has a uuid"

  describe 'replicate_location_values' do
    context 'when choice is for a location option' do
      let(:form) { create(:form, question_types: %w(select_multiple)) }
      let(:questioning) { form.questionings.first }
      let(:option_one) { questioning.options.first }
      let(:option_two) { questioning.options.second }
      let(:latitude) { 12 }
      let(:longitude) { 12 }

      it 'copies the coordinates from the option to the choice lat/long fields' do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option_one.update_attributes(latitude: latitude, longitude: longitude)

        answer = create(:answer, questioning: questioning)
        choice_location = create(:choice, answer: answer, option: option_one)
        choice_other_type = create(:choice, answer: answer, option: option_two)

        expect(choice_location.latitude).to eq latitude
        expect(choice_location.longitude).to eq longitude

        expect(choice_other_type.latitude).to eq nil
        expect(choice_other_type.longitude).to eq nil
      end
    end
  end
end
