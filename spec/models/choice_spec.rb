# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: choices
#
#  id             :uuid             not null, primary key
#  latitude       :decimal(8, 6)
#  longitude      :decimal(9, 6)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  answer_id      :uuid             not null
#  option_node_id :uuid
#
# Indexes
#
#  index_choices_on_answer_id       (answer_id)
#  index_choices_on_option_node_id  (option_node_id)
#
# Foreign Keys
#
#  choices_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...            (option_node_id => option_nodes.id)
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Choice do
  describe "#replicate_location_values" do
    context "when choice is for a location option" do
      let(:form) { create(:form, question_types: %w[select_multiple]) }
      let(:opt_set) { form.c[0].option_set }
      let(:response) do
        create(:response, form: form, answer_values: [[opt_set.c[0].name, opt_set.c[1].name]])
      end
      let(:answer) { response.root_node.c[0] }
      let(:choice_location) { answer.choices.detect { |c| c.option_node == opt_set.c[0] } }
      let(:choice_other_type) { answer.choices.detect { |c| c.option_node == opt_set.c[1] } }

      it "copies the coordinates from the option to the choice lat/long fields" do
        opt_set.update!(geographic: true, allow_coordinates: true)
        opt_set.c[0].option.update!(latitude: 12.34, longitude: 56.78)

        expect(choice_location.latitude).to be_within(0.00001).of(12.34)
        expect(choice_location.longitude).to be_within(0.00001).of(56.78)
        expect(choice_other_type.latitude).to eq(nil)
        expect(choice_other_type.longitude).to eq(nil)
      end
    end
  end
end
