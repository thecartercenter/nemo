require "spec_helper"

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

        # current user
        expect(User.count).to eq(1)
        expect(current_user.active).to be_truthy
      end

      it "deactivates everyone but the current user" do
        users << current_user << user
        destroyer.destroy!

        # users that exist but are not the current user should be deactivated
        User.where.not(email: "current@user.com").each do |u|
          expect(u.active).to be_falsey
        end

        # current user and user with a mission
        expect(User.count).to eq(2)
        expect(current_user.active).to be_truthy
      end
    end

    describe "question" do
      let(:form) { create(:form, :published, question_types: %w[integer]) }
      let(:questions) { create_list(:question, 3) }
      let(:question) { create(:question) }
      let(:questioning) { create(:questioning, question: question) }
      let!(:answer) { create(:answer, questioning: questioning) }
      let(:batch) { questions }

      it "deletes all but the one that has an answer" do

        questions << question
        destroyer.destroy!

        # the only question with an answer
        expect(Question.count).to eq(1)
      end
    end
  end
end
