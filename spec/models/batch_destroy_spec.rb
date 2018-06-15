# frozen_string_literal: true

require "rails_helper"

describe BatchDestroy, type: :model do
  let(:current_user) { create(:user, email: "current@user.com") }
  let(:ability) { Ability.new(user: current_user, mission: get_mission) }
  let(:destroyer) { BatchDestroy.new(batch, current_user, ability) }

  describe "#destroy!" do
    describe "user" do
      let(:users) { create_list(:user, 3) }
      let(:user) { create(:user, mission: create(:mission)) }
      let(:batch) { users }

      it "deletes everyone but the current user" do
        users << current_user
        destroyer.destroy!

        expect(User.all.to_a).to contain_exactly(current_user)
      end

      it "deactivates user with mission and skips current user" do
        users << current_user << user
        destroyer.destroy!

        # users that exist but are not the current user should be deactivated
        User.where.not(email: "current@user.com").each do |u|
          expect(u).not_to be_active
        end

        # current user and user with a mission
        expect(User.all.to_a).to contain_exactly(current_user, user)
      end
    end

    describe "question" do
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
          allow(q1).to receive(:has_answers?) { false }
          allow(q2).to receive(:has_answers?) { false }
          allow(q3).to receive(:has_answers?) { true }
        end

        it "skips questions that have answers" do
          destroyer.destroy!
          expect(Question.all.to_a).to contain_exactly(q3)
        end
      end

      describe "no answers and no published forms" do
        before do
          allow(q1).to receive(:has_answers?) { false }
          allow(q2).to receive(:has_answers?) { false }
          allow(q3).to receive(:published?) { false }
        end

        it "skips questions that have answers" do
          destroyer.destroy!
          expect(Question.count).to eq(0)
        end
      end
    end
  end
end
