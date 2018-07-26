# frozen_string_literal: true

require "rails_helper"

describe "answer location data" do
  let(:form) { create(:form, question_types: question_types) }
  let(:questioning) { form.questionings.first }
  let(:response) { create(:response, form: form, answer_values: [answer_value]) }
  let(:answer) { response.root_node.c[0] } # works when form has one question

  describe ".location_answers_for_mission" do
    let(:question_types) { %w[location select_one select_multiple text integer] }
    before do
      # Configure select one question to be geographic
      select_one_questioning = form.questionings.second
      select_one_option = select_one_questioning.options.first
      select_one_questioning.option_set.update!(geographic: true, allow_coordinates: true)
      select_one_option.update!(latitude: 0, longitude: 0)

      # Configure select multiple question to be geographic
      select_multiple_questioning = form.questionings.third
      option_one = select_multiple_questioning.options.first
      option_two = select_multiple_questioning.options.second
      select_multiple_questioning.option_set.update!(geographic: true, allow_coordinates: true)
      option_one.update!(latitude: 0, longitude: 0)
      option_two.update!(latitude: 0, longitude: 0)

      form.publish!

      create(:response, form: form, answer_values:
        ["12.34 -56.78", select_one_option.name, [option_one.name, option_two.name], "Non geo answer", 12])
    end

    it "returns all answers for locations on a certain mission" do
      location_answers = Answer.location_answers_for_mission(get_mission)
      expect(location_answers.length).to eq(4)
    end
  end

  describe "#location_type_with_value?" do
    let(:answer_value) { "12.34 -56.78" }

    context "with questioning of location type" do
      let(:question_types) { %w[location] }

      it "returns true" do
        expect(answer.location_type_with_value?).to be true
      end
    end

    context "with questioning of a different type" do
      let(:question_types) { %w[text] }

      it "returns false" do
        expect(answer.location_type_with_value?).to be false
      end
    end
  end

  describe "#has_coordinates?" do
    context "with a select_one question" do
      let(:question_types) { %w[select_one] }
      let(:option) { questioning.options.first }
      let(:answer_value) { option.name }

      it "should return false if the selected option does not have coordinates" do
        expect(answer).not_to have_coordinates
      end

      it "should return true if the selected option has coordinates" do
        questioning.option_set.update!(geographic: true, allow_coordinates: true)
        option.update!(latitude: 0, longitude: 0)
        expect(answer).to have_coordinates
      end
    end

    context "with a select_multiple question" do
      let(:question_types) { %w[select_multiple] }
      let(:option_one) { questioning.options.first }
      let(:option_two) { questioning.options.second }
      let(:answer_value) { choices.map(&:option_name) }

      context "with no choices" do
        let(:choices) { [] }

        it "should return false if no options were selected" do
          expect(answer).not_to have_coordinates
        end
      end

      context "with choices" do
        let(:choices) { [build(:choice, option: option_one), build(:choice, option: option_two)] }

        before do
          questioning.option_set.update!(geographic: true, allow_coordinates: true)
        end

        it "should return false if the selected options do not have coordinates" do
          expect(answer).not_to have_coordinates
        end

        it "should return true if all of the selected options have coordinates" do
          option_one.update!(latitude: 0, longitude: 0)
          option_two.update!(latitude: 0, longitude: 0)
          expect(answer).to have_coordinates
        end

        it "should return true if any of the selected options have coordinates" do
          option_one.update!(latitude: 0, longitude: 0)
          expect(answer).to have_coordinates
        end
      end
    end

    context "with a location question" do
      let(:question_types) { %w[location] }

      context "if answer given" do
        let(:answer_value) { "12.3 45.6" }

        it "should return true" do
          expect(answer).to have_coordinates
        end
      end

      context "if answer blank" do
        let(:answer_value) { "" }

        it "should return false" do
          expect(answer).not_to have_coordinates
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
      let(:questioning) { form.questionings.first }
      let(:option) { questioning.options.first }
      let(:answer_value) { option.name }

      it "copies the coordinates from the option to the answer lat/long columns" do
        questioning.option_set.update!(geographic: true, allow_coordinates: true)
        option.update!(latitude: 12.34, longitude: -56.78)
        expect(answer.latitude).to eq(12.34)
        expect(answer.longitude).to eq(-56.78)
      end
    end
  end
end
