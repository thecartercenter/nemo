require 'test_helper'

class Sms::MessageTest < ActiveSupport::TestCase
  test "creating a message with one to number should work" do
    m = Sms::Message.create!(:to => "14045551212", :body => "blah")

    # reload to make sure serialization is working right
    m.reload

    assert_equal(["+14045551212"], m.to)
  end

  test "a message with several to numbers should work" do
    m = Sms::Message.new(:to => ["14045551212", "14045551213"], :body => "blah")
    assert_equal(["+14045551212", "+14045551213"], m.to)
  end

  test "a message with no sent_at should default to now, but only when saved" do
    m = Sms::Message.create(:to => "14045551212", :body => "blah")
    assert(Time.zone.now - m.sent_at < 5.seconds)
  end

  test "a textual from field should be preserved" do
    m = Sms::Message.new(:from => "foo", :body => "blah")
    assert_equal("foo", m.from)
  end

  test "long messages with slight difference at end should not be returned as equal" do
    # this is just to be sure the index of length 160 doesn't mess anything up
    long = "laksdjf alsdkjf lasdfkjaf laskdsf aslkfsjflsakfda lsakl fakjsdlkfaj lskjf alksj " +
      "dfalkj sdlfaks asdaksjdafa alaskdfal alkajdasfa alsjd alasksdjf alks alfdsafdslf l lajslfdjfalsdkf dslads"
    Sms::Message.create(:from => "foo", :body => long)
    assert_nil(Sms::Message.find_by_body(long + "a"))
  end

  test "when a mission is deleted, remove all sms messages from that mission" do
    m = FactoryGirl.create(:sms_message_with_mission)
    Sms::Message.mission_deleted(m.mission)
    assert_nil(Sms::Message.find_by_mission_id(m.id))
  end
end
