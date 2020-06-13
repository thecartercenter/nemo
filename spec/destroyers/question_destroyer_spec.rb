# frozen_string_literal: true

require "rails_helper"

describe QuestionDestroyer do
  let(:current_user) { create(:user, email: "current@user.com") }
  let(:ability) { Ability.new(user: current_user, mission: get_mission) }
  let(:destroyer) { described_class.new(scope: batch, ability: ability) }
  let(:q1) { create(:question) }
  let(:q2) { create(:question) }
  let(:q3) { create(:question) }
  let(:batch) { [q1, q2, q3] }

  describe "published forms" do
    before do
      allow(q1).to receive(:published?) { true }
      allow(q2).to receive(:published?) { true }
      allow(q3).to receive(:published?) { false }
    end

    it "skips questions that are on published forms" do
      destroyer.destroy!
      expect(Question.all.to_a).to contain_exactly(q1, q2)
    end
  end

  describe "answers" do
    before do
      allow(q1).to receive(:data?) { false }
      allow(q2).to receive(:data?) { false }
      allow(q3).to receive(:data?) { true }
    end

    it "skips questions that have answers" do
      destroyer.destroy!
      expect(Question.all.to_a).to contain_exactly(q3)
    end
  end

  describe "no answers and no published forms" do
    before do
      allow(q1).to receive(:data?) { false }
      allow(q2).to receive(:data?) { false }
      allow(q3).to receive(:published?) { false }
    end

    it "skips questions that have answers" do
      destroyer.destroy!
      expect(Question.count).to eq(0)
    end
  end
end
