require 'test_helper'

class Sms::Adapters::IntelliSmsAdapterTest < ActiveSupport::TestCase
  setup do
    @adapter = Sms::Adapters::IntelliSmsAdapter.new
  end
  
  test "delivering a message with one recipient should work" do
    assert_equal(true, @adapter.deliver(Sms::Message.new(:direction => :outgoing, :to => %w(+15556667777), :body => "foo"), :dont_send => true))
  end
  
  test "delivering an invalid message should raise an error" do
    # no recips
    assert_raise(Sms::Error){@adapter.deliver(Sms::Message.new(:direction => :outgoing, :to => [], :body => "foo"), :dont_send => true)}
    
    # wrong direction
    assert_raise(Sms::Error){@adapter.deliver(Sms::Message.new(:direction => :incoming, :to => %w(+15556667777), :body => "foo"), :dont_send => true)}
    
    # no body
    assert_raise(Sms::Error){@adapter.deliver(Sms::Message.new(:direction => :outgoing, :to => %w(+15556667777), :body => ""), :dont_send => true)}
  end
end
