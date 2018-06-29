# frozen_string_literal: true

require "rails_helper"

describe Notifier do
  let!(:mission_1) { create(:mission, name: "Test Mission") }
  let!(:mission_2) { create(:mission) }
  let!(:mission_3) { create(:mission) }
  
  let!(:user) { create(:user, role_name: :staffer, mission: mission_1) }
  let!(:mission_2_coordinator) { create(:user, role_name: :coordinator, mission: mission_2)}
  let!(:mission_3_coordinator) { create(:user, role_name: :coordinator, mission: mission_3)}

  context "password reset email" do

    let(:mail) { described_class.password_reset_instructions(user).deliver_now }

    it "should have user's email in to field" do
      expect(mail.to).to eq [user.email]
    end

    context "user belongs to 1 mission" do

      context "user's mission does not have any coordinator" do
        it "should not have anyone in reply-to" do
          expect(mail.reply_to).to be_empty
        end
      end

      context "user's mission has 1 coordinator" do
        let!(:coordinator) { create(:user, role_name: :coordinator, mission: mission_1)}
        let!(:staffer) { create(:user, role_name: :staffer, mission: mission_1)}
        
        it "should have coordinator's email in reply-to" do
          expect(mail.reply_to).to eq [coordinator.email]
        end

        it "should not have staffer's email in reply-to" do
          expect(mail.reply_to).to_not include staffer.email
        end
      end

      context "user's mission has multiple coordinators" do
        let!(:coordinator_1) { create(:user, role_name: :coordinator, mission: mission_1)}
        let!(:coordinator_2) { create(:user, role_name: :coordinator, mission: mission_1)}

        it "should have all coordinator's email in reply-to" do
          expect(mail.reply_to.length).to eq 2
          expect(mail.reply_to).to include coordinator_1.email
          expect(mail.reply_to).to include coordinator_2.email
        end
      end

    end

    context "user belongs to multiple missions" do
      let!(:mission_1_coordinator_1) { create(:user, role_name: :coordinator, mission: mission_1)}
      let!(:mission_1_coordinator_2) { create(:user, role_name: :coordinator, mission: mission_1)}

      before { user.assignments.create!(mission: mission_2, role: :staffer) } 
      
      it "should have all mission coordinator's email in reply-to" do
        expect(mail.reply_to.length).to eq 3
        expect(mail.reply_to).to include mission_1_coordinator_1.email
        expect(mail.reply_to).to include mission_1_coordinator_2.email
        expect(mail.reply_to).to include mission_2_coordinator.email
      end

      it "should not have other mission coordinator's email in reply-to" do
        expect(mail.reply_to).to_not include mission_3_coordinator.email
      end
    end

  end
end