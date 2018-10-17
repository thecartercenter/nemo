# frozen_string_literal: true

require "rails_helper"

describe Utils::DelayedJobChecker do
  subject(:ok) { described_class.instance.ok? }

  context "with no jobs" do
    it { is_expected.to be(true) }
  end

  context "with jobs" do
    let(:fresh_unhandled) do
      Timecop.travel(-3.seconds) { Delayed::Job.create!(handler: "") }
    end
    let(:old_unhandled) do
      Timecop.travel(-3.minutes) { Delayed::Job.create!(handler: "") }
    end
    let(:handled) do
      Timecop.travel(-3.seconds) { Delayed::Job.create!(handler: "", locked_at: Time.current + 2.seconds) }
    end

    context "with at least one handled job" do
      before { handled && old_unhandled }
      it { is_expected.to be(true) }
    end

    context "with only fresh, unhandled job" do
      before { fresh_unhandled }
      it { is_expected.to be(true) }
    end

    context "with old, unhandled job" do
      before { fresh_unhandled && old_unhandled }
      it { is_expected.to be(false) }
    end
  end
end
