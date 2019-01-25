# frozen_string_literal: true

require "rails_helper"

describe ResponseDestroyer do
  let(:ability) { Ability.new(user: create(:admin), mission: get_mission) }
  let(:result) { described_class.new(scope: scope, ability: ability).destroy! }

  context "with responses" do
    let(:form) { create(:form, question_types: %w[select_one select_multiple image]) }
    let!(:responses) do
      # We don't use create_list because that wouldn't create new images each time.
      Array.new(4) do
        create(:response, form: form, answer_values: ["Cat", %w[Cat Dog], create(:media_image)])
      end
    end
    let(:decoy) { responses[0] }
    let(:scope) { Response.where.not(id: decoy.id) }

    it "ignores decoy, deletes others completely" do
      expect(result).to eq(destroyed: 3, skipped: 0, deactivated: 0)
      expect(Response.count).to eq(1)
      expect(Answer.count).to eq(3)
      expect(Choice.count).to eq(2)
      expect(Media::Object.count).to eq(1)
    end
  end

  context "with no responses" do
    let(:scope) { Response.all }

    it "does nothing" do
      expect(result).to eq(destroyed: 0, skipped: 0, deactivated: 0)
    end
  end
end
