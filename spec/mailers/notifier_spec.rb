# frozen_string_literal: true

require "rails_helper"

describe Notifier do
  context "password reset email" do
    let(:mission) { create(:mission) }
    let(:user) { create(:user, mission: mission, role_name: :enumerator) }
    let(:args) { [user] }
    let(:mail) { described_class.password_reset_instructions(*args).deliver_now }

    it "should have user's email in to field" do
      expect(mail.to).to eq [user.email]
    end

    context "no mission given" do
      it "should not have anyone in reply-to" do
        expect(mail.reply_to).to be_empty
      end
    end

    context "mission given" do
      let(:args) { [user, mission: mission] }

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
end
