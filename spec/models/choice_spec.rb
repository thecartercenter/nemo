require "spec_helper"

describe Choice do
  it_behaves_like "has a uuid"

  describe "#replicate_location_values" do
    context "when choice is for a location option" do
      let(:form) { create(:form, question_types: %w(select_multiple)) }
      let(:questioning) { form.questionings.first }
      let(:option_one) { questioning.options.first }
      let(:option_two) { questioning.options.second }
      let(:answer) { create(:answer, questioning: questioning) }
      let(:choice_location) { create(:choice, answer: answer, option: option_one) }
      let(:choice_other_type) { create(:choice, answer: answer, option: option_two) }

      it "copies the coordinates from the option to the choice lat/long fields" do
        questioning.option_set.update!(geographic: true, allow_coordinates: true)
        option_one.update!(latitude: 12.34, longitude: 56.78)

        expect(choice_location.latitude).to be_within(0.00001).of(12.34)
        expect(choice_location.longitude).to be_within(0.00001).of(56.78)
        expect(choice_other_type.latitude).to eq nil
        expect(choice_other_type.longitude).to eq nil
      end
    end
  end
end
