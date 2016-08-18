require "spec_helper"

describe Broadcast do
  let!(:user1) { create(:user, phone: "+17345550001", role_name: "observer") }
  let!(:user2) { create(:user, phone: "+17345550002", role_name: "observer") }
  let!(:user3) { create(:user, phone: "+17345550003", role_name: "staffer") }
  let!(:userX) { create(:user, phone: "+17345550004", mission: create(:mission)) }

  describe "recipient_numbers" do
    context "with specific_users" do
      let(:broadcast) { create(:broadcast, recipient_selection: "specific_users", recipients: [user1, user3]) }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to eq(%w(+17345550001 +17345550003))
      end
    end

    context "with all_users" do
      let(:broadcast) { create(:broadcast, recipient_selection: "all_users") }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to eq(%w(+17345550001 +17345550002 +17345550003))
      end
    end

    context "with all_users" do
      let(:broadcast) { create(:broadcast, recipient_selection: "all_observers") }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to eq(%w(+17345550001 +17345550002))
      end
    end
  end
end
