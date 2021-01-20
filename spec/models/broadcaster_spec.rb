# frozen_string_literal: true

require "rails_helper"

describe Sms::Broadcaster do
  let!(:mission) { create(:mission) }
  let(:broadcast) { create(:broadcast, :with_recipient_users, medium: "sms", body: "junk") }

  context "with adapter set in mission settings" do
    before do
      mission.setting.update!(default_outgoing_sms_adapter: "Twilio")
    end

    it "builds appropriate adapter and Sms::Broadcast instance" do
      # Let it call original, which will error if adapter doesn't exist.
      expect(Sms::Adapters::Factory.instance).to receive(:create) do |adapter, _config:|
        expect(adapter).to eq("Twilio")
      end.and_call_original
      expect(Sms::Broadcast)
        .to receive(:new).with(broadcast: broadcast, body: "[NEMO] junk", mission: mission).and_call_original
      described_class.new(mission: mission).deliver(broadcast)
    end
  end
end
