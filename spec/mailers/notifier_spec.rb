# frozen_string_literal: true

require "rails_helper"

describe Notifier do
  # This spec covers coordinator reply_to functionality.
  context "intro email" do
    let(:mission) { create(:mission) }
    let(:user) { create(:user, mission: mission, role_name: :enumerator) }
    let(:args) { [user] }
    let(:mail) { described_class.intro(*args).deliver_now }

    context "no mission given" do
      let(:args) { [user] }

      it do
        expect(mail.to).to eq([user.email])
        expect(mail.reply_to).to be_empty
        expect(mail.subject).to eq("Welcome to NEMO!")
        expect(mail.body.encoded).to match("Welcome to NEMO!")
        expect(mail.body.encoded).to match("Your login name is")
        expect(mail.body.encoded).to match("http://www.example.com/en/password-resets/")
      end
    end

    context "mission given" do
      let(:args) { [user, {mission: mission}] }

      it do
        expect(mail.subject).to eq("Welcome to NEMO!")
        expect(mail.body.encoded).to match("Welcome to NEMO!")
      end

      context "mission does not have any coordinator" do
        it "should not have anyone in reply-to" do
          expect(mail.reply_to).to be_empty
        end
      end

      context "mission has coordinators" do
        let!(:coordinator1) { create(:user, role_name: :coordinator, mission: mission) }
        let!(:coordinator2) { create(:user, role_name: :coordinator, mission: mission) }
        let!(:staffer) { create(:user, role_name: :staffer, mission: mission) }

        it "should have all coordinators email in reply-to" do
          expect(mail.reply_to).to contain_exactly(coordinator1.email, coordinator2.email)
        end
      end
    end
  end

  context "password reset email" do
    let(:mission) { create(:mission) }
    let(:user) { create(:user, mission: mission, role_name: :enumerator) }
    let(:args) { [user] }
    let(:mail) { described_class.password_reset_instructions(*args).deliver_now }

    it do
      mail = described_class.password_reset_instructions(user, mission: mission).deliver_now
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Password Reset Instructions")
      expect(mail.body).to match(/A request to reset your NEMO password has been made/)
      expect(mail.body).to match("http://www.example.com/en/password-resets")
    end
  end

  context "sms token change email" do
    let(:mission) { create(:mission) }
    let(:args) { [mission] }
    let(:mail) { described_class.sms_token_change_alert(*args).deliver_now }

    context "mission has coordinators" do
      let!(:coordinator1) { create(:user, role_name: :coordinator, mission: mission) }
      let!(:coordinator2) { create(:user, role_name: :coordinator, mission: mission, admin: true) }
      let!(:staffer1) { create(:user, role_name: :staffer, mission: mission) }
      let!(:staffer2) { create(:user, role_name: :staffer, mission: mission, admin: true) }

      it "should have all coordinators/admins in 'to' and 'reply-to'" do
        expect(mail.to).to contain_exactly(coordinator1.email, coordinator2.email, staffer2.email)
        expect(mail.reply_to).to contain_exactly(coordinator1.email, coordinator2.email, staffer2.email)
      end
    end

    context "mission has inactive admins and coordinators" do
      let!(:coordinator1) { create(:user, role_name: :coordinator, mission: mission, active: false) }
      let!(:coordinator2) { create(:user, role_name: :coordinator, mission: mission) }
      let!(:admin1) { create(:user, role_name: :staffer, mission: mission, admin: true, active: false) }
      let!(:admin2) { create(:user, role_name: :staffer, mission: mission, admin: true) }

      it "should only email active users" do
        expect(mail.to).to contain_exactly(coordinator2.email, admin2.email)
        expect(mail.reply_to).to contain_exactly(coordinator2.email, admin2.email)
      end
    end
  end

  context "warning alert email" do
    let(:error) { StandardError.new("Test") }
    let(:mail) { described_class.bug_tracker_warning(error).deliver_now }

    it do
      expect(mail.to).to eq(%w[test1@getnemo.org test2@getnemo.org])
      expect(mail.subject).to match(/StandardError/)
      expect(mail.body).to match(/in Sentry/)
    end
  end
end
