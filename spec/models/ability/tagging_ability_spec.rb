# frozen_string_literal: true

require "rails_helper"

describe Tagging do
  subject(:ability) do
    user = create(:user, role_name: "coordinator")
    Ability.new(user: user, mission: get_mission)
  end

  before do
    @question = build(:question)
    @tagging = build(:tagging, question: @question)
  end

  it { should be_able_to(:update, @tagging) }
  it { should be_able_to(:destroy, @tagging) }

  context "if belongs to standard question" do
    before { @question.mission = nil }

    it { should be_able_to(:update, @tagging) }
    it { should be_able_to(:destroy, @tagging) }
  end
end
