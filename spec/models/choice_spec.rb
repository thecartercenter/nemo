# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: choices
#
#  id         :uuid             not null, primary key
#  latitude   :decimal(8, 6)
#  longitude  :decimal(9, 6)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :uuid             not null
#  option_id  :uuid             not null
#
# Indexes
#
#  index_choices_on_answer_id                (answer_id)
#  index_choices_on_answer_id_and_option_id  (answer_id,option_id) UNIQUE
#  index_choices_on_option_id                (option_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  choices_option_id_fkey  (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

require "rails_helper"

describe Choice do
  describe "#replicate_location_values" do
    context "when choice is for a location option" do
      let(:form) { create(:form, question_types: %w[select_multiple]) }
      let(:questioning) { form.c[0] }
      let(:option_one) { questioning.options[0] }
      let(:option_two) { questioning.options[1] }
      let(:response) { create(:response, form: form, answer_values: [[option_one.name, option_two.name]]) }
      let(:answer) { response.root_node.c[0] }
      let(:choice_location) { answer.choices.detect { |c| c.option == option_one } }
      let(:choice_other_type) { answer.choices.detect { |c| c.option == option_two } }

      it "copies the coordinates from the option to the choice lat/long fields" do
        questioning.option_set.update!(geographic: true, allow_coordinates: true)
        option_one.update!(latitude: 12.34, longitude: 56.78)

        expect(choice_location.latitude).to be_within(0.00001).of(12.34)
        expect(choice_location.longitude).to be_within(0.00001).of(56.78)
        expect(choice_other_type.latitude).to eq(nil)
        expect(choice_other_type.longitude).to eq(nil)
      end
    end
  end
end
