require "rails_helper"

describe User do
  let(:mission) { get_mission }

  describe "creation" do
    let(:user) { create(:user, email: "foo@bar.com") }

    it "should have an api_key generated" do
      expect(user.api_key).to_not be_blank
    end

    it "should have an SMS auth code generated" do
      expect(user.sms_auth_code).to_not be_blank
    end

    context "when distinct user exists with same email" do
      let(:other_user) { create(:user, email: "foo@bar.com") }

      it "should allow creation" do
        expect(user.email).to eq other_user.email
      end
    end
  end

  describe "best_mission" do
    before do
      @user = build(:user)
    end

    context "with no last mission" do
      context "with no assignments" do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end

      context "with assignments" do
        before do
          allow(@user).to receive(:assignments).and_return([
                           build(:assignment, user: @user, updated_at: 2.days.ago),
            @most_recent = build(:assignment, user: @user, updated_at: 1.hour.ago),
                           build(:assignment, user: @user, updated_at: 1.day.ago)
          ])
        end

        it "should return the mission from the most recently updated assignment" do
          expect(@user.best_mission).to eq @most_recent.mission
        end
      end
    end

    context "with last mission" do
      before do
        @last_mission = build(:mission)
        allow(@user).to receive(:last_mission).and_return(@last_mission)
      end

      context "and a more recent assignment to another mission" do
        before do
          allow(@user).to receive(:assignments).and_return([
            build(:assignment, user: @user, mission: @last_mission, updated_at: 2.days.ago),
            build(:assignment, user: @user, updated_at: 1.hour.ago)
          ])
        end

        specify { expect(@user.best_mission.name).to eq @last_mission.name }
      end

      context "but no longer assigned to last mission" do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end
    end
  end

  describe "username validation" do
    it "should allow letters numbers and periods" do
      ["foobar", "foo.bar9", "1234", "..1_23"].each do |login|
        user = build(:user, login: login)
        expect(user).to be_valid
      end
    end

    it "should not allow invalid chars" do
      ["foo bar", "foo✓bar", "foébar", "foo'bar"].each do |login|
        user = build(:user, login: login)
        expect(user).not_to be_valid
        expect(user.errors[:login].join).to match /letters, numbers, periods/
      end
    end

    it "should trim spaces and convert to lowercase" do
      user = build(:user, login: "FOOBAR  \n ")
      expect(user).to be_valid
      expect(user.login).to eq "foobar"
    end

    describe "uniqueness" do
      let!(:user) { create(:user, login: "jayita") }

      it "returns an error when the login is not unique" do
        user2 = build(:user, login: "jayita")
        expect(user2).not_to be_valid
        expect(user2.errors.full_messages.join).to match(/Username: Please enter a unique value/)
      end

      it "can create a user with the same login after deleting" do
        user.destroy
        user2 = build(:user, login: "jayita")
        expect(user2).to be_valid
      end
    end
  end

  it "creating a user with minimal info should produce good defaults", :investigate do
    user = User.create!(name: "Alpha Tester", login: "alpha", reset_password_method: "print",
                        assignments: [Assignment.new(mission: mission, role: User::ROLES.first)])
    expect(user.pref_lang).to eq("en")
    expect(user.login).to eq("alpha")
  end

  private

  def assert_phone_uniqueness_error(user)
    user.valid?
    expect(user.errors.full_messages.join).to match(/phone.+assigned/i)
  end
end
