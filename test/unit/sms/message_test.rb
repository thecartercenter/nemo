require 'test_helper'

class Sms::MessageTest < ActiveSupport::TestCase
  test "creating a message with one to number should work" do
    m = Sms::Message.create!(:to => "14045551212", :body => "blah")

    # reload to make sure serialization is working right
    m.reload
    
    assert_equal(["+14045551212"], m.to)
  end
  
  test "a message with several to numbers should work" do
    m = Sms::Message.create!(:to => ["14045551212", "14045551213"], :body => "blah")
    assert_equal(["+14045551212", "+14045551213"], m.to)
  end
  
  test "a message with no sent_at should default to now" do
    m = Sms::Message.create!(:to => "14045551212", :body => "blah")
    assert(Time.zone.now - m.sent_at < 5.seconds)
  end
  
  test "a textual from field should be preserved" do
    m = Sms::Message.create!(:from => "foo", :body => "blah")
    assert_equal("foo", m.from)
  end
end
