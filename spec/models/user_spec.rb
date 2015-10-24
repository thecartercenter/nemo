require 'spec_helper'

describe User do
  let(:mission) { get_mission }

  context 'when user is created' do
    before do
      @user = create(:user)
    end

    it 'should have an api_key generated' do
      expect(@user.api_key).to_not be_blank
    end
  end

  describe 'best_mission' do
    before do
      @user = build(:user)
    end

    context 'with no last mission' do
      context 'with no assignments' do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end

      context 'with assignments' do
        before do
          allow(@user).to receive(:assignments).and_return([
                           build(:assignment, user: @user, updated_at: 2.days.ago),
            @most_recent = build(:assignment, user: @user, updated_at: 1.hour.ago),
                           build(:assignment, user: @user, updated_at: 1.day.ago)
          ])
        end

        it 'should return the mission from the most recently updated assignment' do
          expect(@user.best_mission).to eq @most_recent.mission
        end
      end
    end

    context 'with last mission' do
      before do
        @last_mission = build(:mission)
        allow(@user).to receive(:last_mission).and_return(@last_mission)
      end

      context 'and a more recent assignment to another mission' do
        before do
          allow(@user).to receive(:assignments).and_return([
            build(:assignment, user: @user, mission: @last_mission, updated_at: 2.days.ago),
            build(:assignment, user: @user, updated_at: 1.hour.ago)
          ])
        end

        specify { expect(@user.best_mission).to eq @last_mission }
      end

      context 'but no longer assigned to last mission' do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end
    end
  end

  describe "username suggestion" do
    context "for batch imports" do
      let(:user) { User.new(name: 'Test User', batch_creation: true) }

      it "should join name parts with a period" do
        expect(user.login).to eq 'test.user'
      end
    end

    context "for non-batch imports" do
      let(:user) { User.new(name: 'Another Test User') }

      it "should replace spaces with periods" do
        expect(user.login).to eq 'another.test.user'
      end

      context "with single name" do
        let(:user) { User.new(name: 'Name') }

        it "should use the name" do
          expect(user.login).to eq 'name'
        end
      end

      context "with first and last name" do
        let(:user) { User.new(name: 'First Last') }

        it "should suggest first initial with last name" do
          expect(user.login).to eq 'flast'
        end
      end

      context "with unicode names" do
        let(:user) { User.new(name: '宮本 茂') }

        it "should allow unicode charters in the login" do
          expect(user.login).to eq '宮本.茂'
        end
      end
    end
  end

  it "creating a user with minimal info should produce good defaults" do
    user = User.create!(name: 'Alpha Tester', reset_password_method: 'print',
      assignments: [Assignment.new(mission: mission, role: User::ROLES.first)])
    expect(user.pref_lang).to eq('en')
    expect(user.login).to eq('atester')
  end

  it "phone numbers should be unique" do
    # create a user with two phone numbers
    first = create(:user, phone: "+19998887777", phone2: "+17776665537")

    assert_phone_uniqueness_error(build(:user, login: "foo", phone: "+19998887777"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone2: "+19998887777"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone: "+17776665537"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone2: "+17776665537"))

    # User with no phone.
    second = build(:user, login: "foo")
    expect(second).to be_valid

    # Try to edit this new user to conflicting phone number, should fail
    second.assign_attributes(phone: "+19998887777")
    assert_phone_uniqueness_error(second)

    # Create a user with different phone numbers and make sure no error
    third = build(:user, login: "bar", phone: "+19998887770", phone2: "+17776665530")
    expect(third).to be_valid
  end

  private
  def assert_phone_uniqueness_error(user)
    user.valid?
    expect(user.errors.full_messages.join).to match(/phone.+assigned/i)
  end
end
