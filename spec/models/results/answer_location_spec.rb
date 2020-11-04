# frozen_string_literal: true

require "rails_helper"

describe "answer location data" do
  let(:form) { create(:form, :live, question_types: question_types) }
  let(:response) { create(:response, form: form, answer_values: [answer_value]) }
  let(:answer) { response.root_node.c[0] } # works when form has one question

  describe "#location_type_with_value?" do
    let(:answer_value) { "12.34 -56.78" }

    context "with questioning of location type" do
      let(:question_types) { %w[location] }

      it "returns true" do
        expect(answer.location_type_with_value?).to be(true)
      end
    end

    context "with questioning of a different type" do
      let(:question_types) { %w[text] }

      it "returns false" do
        expect(answer.location_type_with_value?).to be(false)
      end
    end
  end

  describe "#coordinates?" do
    context "with a select_one question" do
      let(:question_types) { %w[select_one] }
      let(:option) { form.c[0].first_level_option_nodes[0].option }
      let(:answer_value) { option.name }

      it "should return false if the selected option does not have coordinates" do
        expect(answer.coordinates?).to be(false)
      end

      it "should return true if the selected option has coordinates" do
        form.c[0].option_set.update!(geographic: true, allow_coordinates: true)
        option.update!(latitude: 0, longitude: 0)
        expect(answer.coordinates?).to be(true)
      end
    end

    context "with a select_multiple question" do
      let(:question_types) { %w[select_multiple] }
      let(:option_node1) { form.c[0].first_level_option_nodes[0] }
      let(:option_node2) { form.c[0].first_level_option_nodes[1] }
      let(:answer_value) { choices.map(&:option_name) }

      context "with no choices" do
        let(:choices) { [] }

        it "should return false if no options were selected" do
          expect(answer.coordinates?).to be(false)
        end
      end

      context "with choices" do
        let(:choices) do
          [build(:choice, option_node: option_node1), build(:choice, option_node: option_node2)]
        end

        before do
          form.c[0].option_set.update!(geographic: true, allow_coordinates: true)
        end

        it "should return false if the selected options do not have coordinates" do
          expect(answer.coordinates?).to be(false)
        end

        it "should return false if some of the selected options have coordinates" do
          option_node1.option.update!(latitude: 0, longitude: 0)
          expect(answer.coordinates?).to be(false)
        end
      end
    end

    context "with a location question" do
      let(:question_types) { %w[location] }

      context "if answer given" do
        let(:answer_value) { "12.3 45.6" }

        it "should return true" do
          expect(answer.coordinates?).to be(true)
        end
      end

      context "if answer blank" do
        let(:answer_value) { "" }

        it "should return false" do
          expect(answer.coordinates?).to be(false)
        end
      end
    end
  end

  describe "#replicate_location_values" do
    context "when the answer is for simple location type question" do
      let(:question_types) { %w[location] }
      let(:answer_value) { "12.34 -56.78" }
      it "copies the coordinates from value to the lat/long fields" do
        expect(answer).to be_location_type_with_value
        expect(answer.latitude).to eq(12.34)
        expect(answer.longitude).to eq(-56.78)
      end
    end

    context "when answer is for a select one question of a location" do
      let(:question_types) { %w[select_one] }
      let(:option) { form.c[0].first_level_option_nodes[0].option }
      let(:answer_value) { option.name }

      it "copies the coordinates from the option to the answer lat/long columns" do
        form.c[0].option_set.update!(geographic: true, allow_coordinates: true)
        option.update!(latitude: 12.34, longitude: -56.78)
        expect(answer.latitude).to eq(12.34)
        expect(answer.longitude).to eq(-56.78)
      end
    end
  end
end
