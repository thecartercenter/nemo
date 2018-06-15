require "rails_helper"

describe "abilities for reports" do

  let(:own_report) { create(:report, creator: user) }
  let(:not_own_report) { create(:report, creator: create(:user)) }
  let(:anon_report) { create(:report, creator: nil) }
  let(:ability) { Ability.new(user: user, mission: get_mission) }

  context "coordinator" do
    let(:user) { create(:user, role_name: :coordinator) }

    it "should be able to do all" do
      expect(ability).to be_able_to(:create, Report::Report)
      [:read, :update, :delete, :export].each do |a|
        expect(ability).to be_able_to(a, own_report)
        expect(ability).to be_able_to(a, not_own_report)
        expect(ability).to be_able_to(a, anon_report)
      end
    end
  end

  shared_examples_for "restricted" do |role|

    let(:user) { create(:user, role_name: role) }

    it "should be able to create" do
      expect(ability).to be_able_to(:create, Report::Report)
    end

    it "should be able to view all" do
      expect(ability).to be_able_to(:read, own_report)
      expect(ability).to be_able_to(:read, not_own_report)
      expect(ability).to be_able_to(:read, anon_report)
    end

    it "should be able to update and delete own only" do
      expect(ability).to be_able_to(:update, own_report)
      expect(ability).not_to be_able_to(:update, not_own_report)
      expect(ability).not_to be_able_to(:update, anon_report)
      expect(ability).to be_able_to(:destroy, own_report)
      expect(ability).not_to be_able_to(:destroy, not_own_report)
      expect(ability).not_to be_able_to(:destroy, anon_report)
    end
  end

  context "staffer" do
    it_behaves_like "restricted", :staffer
  end

  context "reviewer" do
    let(:user) { create(:user, role_name: :reviewer) }

    it "should not be able to export reports" do
      expect(ability).not_to be_able_to(:export, own_report)
      expect(ability).not_to be_able_to(:export, not_own_report)
      expect(ability).not_to be_able_to(:export, anon_report)
    end

    it_behaves_like "restricted", :reviewer
  end

  context "enumerator" do
    let(:user) { create(:user, role_name: :enumerator) }

    it "should not be able to export reports" do
      expect(ability).not_to be_able_to(:export, own_report)
      expect(ability).not_to be_able_to(:export, not_own_report)
      expect(ability).not_to be_able_to(:export, anon_report)
    end

    it_behaves_like "restricted", :enumerator
  end

end
