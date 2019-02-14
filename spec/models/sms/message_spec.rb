# frozen_string_literal: true

require "rails_helper"

describe Sms::Message, :sms do
  let(:body) { "blah" }
  let(:from) { "+17345551212" }
  let!(:message) { create(:sms_reply, from: from, to: "14045551212", body: body) }

  it "creating a message should work" do
    message.reload # reload to make sure serialization is working right
    expect(message.to).to eq("+14045551212")
  end

  it "a message with no sent_at should default to now, but only when saved" do
    expect(Time.current - message.sent_at < 5.seconds).to be(true)
  end

  context "with textual from" do
    let(:from) { "foo" }

    it "should be preserved" do
      expect(message.from).to eq("foo")
    end
  end

  context "with long body and slight difference at end" do
    let(:body) do
      "laksdjf alsdkjf lasdfkjaf laskdsf aslkfsjflsakfda lsakl fakjsdlkfaj lskjf alksj "\
      "dfalkj sdlfaks asdaksjdafa alaskdfal alkajdasfa alsjd alasksdjf alks"\
      "alfdsafdslf l lajslfdjfalsdkf dslads"
    end

    it "should not be returned as equal" do
      # This is just to be sure the index of length 160 doesn't mess anything up
      expect(Sms::Reply.find_by(body: body)).to eq(message)
      expect(Sms::Reply.find_by(body: body + "a")).to be_nil
    end
  end
end
