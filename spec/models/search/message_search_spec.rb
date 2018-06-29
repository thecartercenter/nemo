require "rails_helper"

describe Sms::Message do
  describe "search" do
    describe "date search" do
      let(:m1) { create(:sms_incoming, created_at: "2017-01-01 22:00") }

      around do |example|
        in_timezone("Saskatchewan") { example.run }
      end

      it "should work even if timestamp in UTC is the next day" do
        expect(search "date:2017-01-01").to eq [m1]
      end
    end
  end

  def search(query)
    Sms::Message.do_search(Sms::Message, query, nil)
  end
end
