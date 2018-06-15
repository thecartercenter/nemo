require "rails_helper"

describe Response do
  let(:user) { create(:user, role_name: "enumerator") }

  subject(:ability) do
    Ability.new(user: user, mission: get_mission)
  end

  let(:form) do
    FactoryGirl.create(:form,
      name: "SMS Form", smsable: true, mission: get_mission, question_types: %w(integer text))
  end
  let(:form_answers) { [1, "Lorem ipsum try me again"] }
  let(:response) { create(:response, form: form, answer_values: form_answers) }
  let(:own_response) { create(:response, form: form, answer_values: form_answers, user: user) }

  context "as an enumerator" do
    it "should be able to create a response" do
      expect(ability).to be_able_to :create, own_response
    end

    it "should be able to edit own response" do
      expect(ability).to be_able_to :edit, own_response
    end

    it "should not be able to see, modify, or delete the responses of others" do
      %w(index show new create edit update destroy delete review export).each do |action|
        expect(ability).to_not be_able_to action.to_sym, response
      end
    end
  end

  context "as a reviewer" do
    let(:user) { create(:user, role_name: "reviewer") }

    it "should be able to create a response" do
      expect(ability).to be_able_to :create, own_response
    end

    it "should be able to edit own response" do
      expect(ability).to be_able_to :edit, own_response
      expect(ability).to be_able_to :modify_answers, own_response
      expect(ability).to be_able_to :update, own_response
      expect(ability).to be_able_to :destroy, own_response
    end

    it "should be able to view others responses" do
      expect(ability).to be_able_to :index, response
      expect(ability).to be_able_to :show, response
    end

    it "should be able to review others responses" do
      expect(ability).to be_able_to :review, response
    end

    it "should not be able to edit or otherwise modify others responses" do
      %w(modify destroy delete export).each do |action|
        expect(ability).to_not be_able_to action.to_sym, response
      end
    end
  end
end
