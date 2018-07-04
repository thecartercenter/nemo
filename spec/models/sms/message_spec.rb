require 'rails_helper'

describe Sms::Message, :sms do
  it "creating a message should work" do
    m = Sms::Reply.create!(to: "14045551212", body: "blah")
    m.reload # reload to make sure serialization is working right
    expect(m.to).to eq("+14045551212")
  end

  it "a message with no sent_at should default to now, but only when saved" do
    m = Sms::Reply.create(to: "14045551212", body: "blah")
    expect(Time.zone.now - m.sent_at < 5.seconds).to be true
  end

  it "a textual from field should be preserved" do
    m = Sms::Reply.new(from: "foo", body: "blah")
    expect(m.from).to eq("foo")
  end

  it "long messages with slight difference at end should not be returned as equal" do
    # this is just to be sure the index of length 160 doesn't mess anything up
    long = "laksdjf alsdkjf lasdfkjaf laskdsf aslkfsjflsakfda lsakl fakjsdlkfaj lskjf alksj " +
      "dfalkj sdlfaks asdaksjdafa alaskdfal alkajdasfa alsjd alasksdjf alks alfdsafdslf l lajslfdjfalsdkf dslads"
    Sms::Reply.create(from: "foo", body: long)
    expect(Sms::Reply.find_by_body(long + "a")).to be_nil
  end

  it "when a mission is deleted, remove all sms messages from that mission" do
    sms = create(:sms_message_with_mission)
    Sms::Message.mission_pre_delete(sms.mission)
    expect(Sms::Message.find_by_mission_id(sms.id)).to be_nil
  end
end
