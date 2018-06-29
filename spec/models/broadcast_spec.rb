require "rails_helper"

describe Broadcast do
  let!(:user1) { create(:user, phone: "+17345550001", role_name: "enumerator") }
  let!(:user2) { create(:user, phone: "+17345550002", role_name: "enumerator") }
  let!(:user3) { create(:user, phone: "+17345550003", role_name: "staffer") }
  let!(:user4) { create(:user, phone: "+17345550004", role_name: "coordinator") }
  let!(:user5) { create(:user, phone: "+17345550005", role_name: "coordinator") }
  let!(:group1) { create(:user_group, users: [user1, user4]) }
  let!(:group2) { create(:user_group, users: [user2]) }
  let!(:userX) { create(:user, phone: "+17345550006", mission: create(:mission)) }

  describe "recipient_numbers" do
    context "with specific users" do
      let(:broadcast) { create(:broadcast,
        recipient_selection: "specific",
        recipient_users: [user1, user3]) }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to contain_exactly(*%w(+17345550001 +17345550003))
      end
    end

    context "with specific users and groups" do
      let(:broadcast) { create(:broadcast,
        recipient_selection: "specific",
        recipient_users: [user5, user4],
        recipient_groups: [group1, group2]) }

      it "returns correct numbers without duplication" do
        expect(broadcast.recipient_numbers).to contain_exactly(
          *%w(+17345550005 +17345550004 +17345550001 +17345550002))
      end
    end

    context "with all_users" do
      let(:broadcast) { create(:broadcast, recipient_selection: "all_users") }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to contain_exactly(
          *%w(+17345550001 +17345550002 +17345550003 +17345550004 +17345550005))
      end
    end

    context "with all_users" do
      let(:broadcast) { create(:broadcast, recipient_selection: "all_enumerators") }

      it "returns correct numbers" do
        expect(broadcast.recipient_numbers).to contain_exactly(*%w(+17345550001 +17345550002))
      end
    end

    context "with both_numbers" do
      let!(:user1) { create(:user, phone: "+17345550011", phone2: "+17345550021", role_name: "enumerator") }
      let!(:user2) { create(:user, phone: nil, phone2: "+17345550022", role_name: "enumerator") }
      let!(:user3) { create(:user, phone: "+17345550013", phone2: nil, role_name: "staffer") }
      let(:broadcast) do
        create(:broadcast,
          recipient_selection: "specific",
          recipient_users: [user1, user2, user3],
          which_phone: "both")
      end

      it "uses both available numbers for all users and eliminates nulls" do
        expect(broadcast.recipient_numbers).to contain_exactly(
          *%w(+17345550011 +17345550021 +17345550022 +17345550013))
      end
    end
  end
end
