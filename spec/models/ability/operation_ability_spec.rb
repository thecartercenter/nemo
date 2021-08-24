# frozen_string_literal: true

require "rails_helper"

describe Operation do
  let!(:own_operation) { create(:operation, creator: actor) }
  let!(:other_operation) { create(:operation, creator: create(:user)) }

  subject(:ability) do
    Ability.new(user: actor, mission: get_mission)
  end

  context "as admin" do
    let(:actor) { create(:admin) }

    it "should be able to access all operations" do
      expect(ability).to be_able_to(:index, Operation)
      expect(ability).to be_able_to(:clear, Operation)
      expect(ability).to be_able_to(:show, own_operation)
      expect(ability).to be_able_to(:destroy, own_operation)
      expect(ability).to be_able_to(:show, other_operation)
      expect(ability).to be_able_to(:destroy, other_operation)
    end

    it "manage should not be used" do
      expect(ability).not_to be_able_to(:manage, own_operation)
    end

    it "should scope properly" do
      expect(Operation.accessible_by(ability).to_a).to contain_exactly(own_operation, other_operation)
    end

    context "with in progress operation" do
      let(:operation) { create(:operation, provider_job_id: "xxx") }

      it "should be able to show, but not destroy if started" do
        expect(ability).to be_able_to(:show, operation)
        expect(ability).to be_able_to(:destroy, operation)
        expect(Delayed::Job).to receive(:exists?).and_return(true)
        operation.job_started_at = Time.zone.now
        expect(ability).not_to be_able_to(:destroy, operation)
      end
    end
  end

  context "as non-admin" do
    let(:actor) { create(:user, role_name: :coordinator) }

    it "should be able to access only own operations" do
      expect(ability).to be_able_to(:index, Operation)
      expect(ability).to be_able_to(:clear, Operation)
      expect(ability).to be_able_to(:show, own_operation)
      expect(ability).to be_able_to(:destroy, own_operation)
      expect(ability).not_to be_able_to(:show, other_operation)
      expect(ability).not_to be_able_to(:destroy, other_operation)
    end

    it "should scope properly" do
      expect(Operation.accessible_by(ability).to_a).to contain_exactly(own_operation)
    end
  end
end
