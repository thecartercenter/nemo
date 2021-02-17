# frozen_string_literal: true

shared_context "sms adapters" do
  shared_examples_for "all adapters that can deliver messages" do
    it "delivering a message with one recipient should work" do
      expect(adapter.deliver(Sms::Reply.new(to: "+15556667777", body: "foo"))).to be(true)
    end

    it "delivering a message with no recipients should raise an error" do
      expect do
        adapter.deliver(Sms::Reply.new(to: nil, body: "foo"))
      end.to raise_error(Sms::Error)
    end

    it "deliering a message with no body should raise an error" do
      expect do
        adapter.deliver(Sms::Reply.new(to: "+15556667777", body: ""))
      end.to raise_error(Sms::Error)
    end
  end
end
