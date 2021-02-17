# frozen_string_literal: true

require "rails_helper"

describe BroadcastMailer do
  let(:mission) { get_mission }

  it do
    mail = described_class.broadcast(to: ["foo@bar.com"], subject: "Foo", body: "Bar", mission: mission)
    expect(mail.to).to eq(["foo@bar.com"])
    expect(mail.subject).to eq("[NEMO] Foo")
    expect(mail.body.encoded).to eq("[This is a broadcast message from NEMO]\r\n\r\nBar\r\n")
  end
end
