# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: users
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE), not null
#  admin             :boolean          default(FALSE), not null
#  api_key           :string(255)
#  birth_year        :integer
#  crypted_password  :string(255)      not null
#  current_login_at  :datetime
#  editor_preference :string
#  email             :string(255)
#  experience        :text
#  gender            :string(255)
#  gender_custom     :string(255)
#  import_num        :integer
#  last_request_at   :datetime
#  login             :string(255)      not null
#  login_count       :integer          default(0), not null
#  name              :string(255)      not null
#  nationality       :string(255)
#  notes             :text
#  password_salt     :string(255)      not null
#  perishable_token  :string(255)
#  persistence_token :string(255)
#  phone             :string(255)
#  phone2            :string(255)
#  pref_lang         :string(255)      default("en"), not null
#  sms_auth_code     :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  last_mission_id   :uuid
#
# Indexes
#
#  index_users_on_email            (email)
#  index_users_on_last_mission_id  (last_mission_id)
#  index_users_on_login            (login) UNIQUE
#  index_users_on_name             (name)
#  index_users_on_sms_auth_code    (sms_auth_code) UNIQUE
#
# Foreign Keys
#
#  users_last_mission_id_fkey  (last_mission_id => missions.id) ON DELETE => nullify ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe User do
  let(:mission) { get_mission }

  describe "validation" do
    describe "password strength" do
      let(:user) do
        build(:user, password: password, password_confirmation: password)
      end

      shared_examples_for "too weak" do
        it do
          expect(user).not_to be_valid
          expect(user.errors[:password]).to include(
            "Password must include at least one number, one lowercase letter, and one capital letter."
          )
        end
      end

      context "with new record" do
        context "with weak password" do
          let(:password) { "passw0rd" }

          it_behaves_like "too weak"
        end

        context "with dictionary password" do
          let(:password) { "contortionist" }

          it_behaves_like "too weak"
        end

        context "with strong password" do
          let(:password) { "2a89fhq;*42ata2;84ty8;Q:4t8qa" }

          it { expect(user).to be_valid }
        end
      end

      context "with persisted record" do
        let(:password) { "2a89fhq;*42ata2;84ty8;Q:4t8qa" }
        let(:saved) do
          create(:user, password: password, password_confirmation: password)
        end
        let(:user) { User.find(saved.id) } # Reload so password is definitely wiped.

        it "updates cleanly when password not set" do
          user.phone = "+1234567890"
          expect(user).to be_valid
        end

        it "updates cleanly when password nil" do
          user.update!(phone: "+1234567890", password: nil)
        end

        it "updates cleanly when password empty string" do
          user.update!(phone: "+1234567890", password: "")
        end

        it "updates cleanly when password and confirmation nil" do
          user.update!(phone: "+1234567890", password: nil, password_confirmation: nil)
        end

        it "updates cleanly when password and confirmation empty string" do
          user.update!(phone: "+1234567890", password: "", password_confirmation: "")
        end

        it "errors when password changed and invalid" do
          user.update(phone: "+1234567890", password: "foo", password_confirmation: "foo")
          expect(user.errors[:password].join).to match(/must include/)
        end
      end
    end

    describe "password confirmation" do
      let(:password) { "2a89fhq;*42ata2;84ty8;Q:4t8qa" }
      let(:user) { build(:user, password: password, password_confirmation: confirmation) }

      context "with matching confirmaiton" do
        let(:confirmation) { password }

        it { expect(user).to be_valid }
      end

      context "without matching confirmation" do
        let(:confirmation) { "x" }

        it do
          expect(user).not_to be_valid
          expect(user.errors[:password_confirmation]).to include("doesn't match Password")
        end
      end
    end
  end

  describe "creation" do
    let(:user) { create(:user, email: "foo@bar.com") }

    it "should have an api_key generated" do
      expect(user.api_key).to_not(be_blank)
    end

    it "should have an SMS auth code generated" do
      expect(user.sms_auth_code).to_not(be_blank)
    end

    context "when distinct user exists with same email" do
      let(:other_user) { create(:user, email: "foo@bar.com") }

      it "should allow creation" do
        expect(user.email).to eq(other_user.email)
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
          expect(@user.best_mission).to eq(@most_recent.mission)
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

        specify { expect(@user.best_mission.name).to eq(@last_mission.name) }
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

    it "should allow unicode word chars" do
      %w[foo_bar.baz 123 foébar テスト].each do |login|
        user = build(:user, login: login)
        expect(user).to be_valid, "Expected login to be allowed: #{login}"
      end
    end

    it "should disallow unicode non-word chars" do
      ["foo bar", "foo\nbar", "foo'bar", "foo✓bar", "foo😂bar", "foo\u00A0bar"].each do |login|
        user = build(:user, login: login)
        expect(user).not_to be_valid
        # TODO: Update error messages.
        expect(user.errors[:login].join)
          .to match(/letters, numbers, periods/), "Expected login to be disallowed: #{login}"
      end
    end

    it "should trim spaces and convert to lowercase" do
      user = build(:user, login: "FOOBAR  \n ")
      expect(user).to be_valid
      expect(user.login).to eq("foobar")
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

  describe "destruction" do
    let!(:user) { create(:user) }

    context "without associations" do
      it "destroys cleanly" do
        user.destroy
      end
    end

    context "with submitted response" do
      let!(:response) { create(:response, user: user) }

      it "raises DeleteRestrictionError" do
        expect { user.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError) do |e|
          # We test the exact wording of the error because the last word is sometimes used to
          # lookup i18n strings.
          expect(e.to_s).to eq("Cannot delete record because of dependent responses")
        end
      end
    end

    context "with reviewed response" do
      let!(:response) { create(:response, reviewer: user) }

      it "raises DeleteRestrictionError" do
        expect { user.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError) do |e|
          # We test the exact wording of the error because the last word is sometimes used to
          # lookup i18n strings.
          expect(e.to_s).to eq("Cannot delete record because of dependent reviewed_responses")
        end
      end
    end

    context "with checked out response" do
      let!(:response) { create(:response, checked_out_by: user) }

      it "nullifies" do
        user.destroy
        expect(response.reload.checked_out_by).to be_nil
      end
    end

    context "with SMS message" do
      let!(:message) { create(:sms_reply, user: user) }

      it "raises DeleteRestrictionError" do
        expect { user.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError) do |e|
          # We test the exact wording of the error because the last word is sometimes used to
          # lookup i18n strings.
          expect(e.to_s).to eq("Cannot delete record because of dependent sms_messages")
        end
      end
    end
  end

  private

  def assert_phone_uniqueness_error(user)
    user.valid?
    expect(user.errors.full_messages.join).to match(/phone.+assigned/i)
  end
end
