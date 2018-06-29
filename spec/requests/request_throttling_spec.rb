require "rails_helper"

describe "throttling for xml requests" do
  let(:limit) { configatron.direct_auth_request_limit }

  before(:all) do
    configatron.allow_unauthenticated_submissions = true
    Rack::Attack.enable!
  end

  after(:all) do
    configatron.allow_unauthenticated_submissions = false
    Rack::Attack.disable!
  end

  after(:all) do
    configatron.allow_unauthenticated_submissions = false
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  context "with the same ip address" do
    it "should not apply to requests below the limit" do
      limit.times do
        get "/m/#{get_mission.compact_name}/formList"
        assert_response :unauthorized
      end
    end

    it "should apply to requests above the limit with response code 429" do
      (limit + 1).times do |i|
        get "/m/#{get_mission.compact_name}/formList"
        if i < limit
          assert_response :unauthorized
        else
          assert_response :too_many_requests
        end
      end
    end

    it "should apply to /m/mission_name/noauth/submission requests above the limit with response code 429" do
      (limit + 1).times do |i|
        post "/m/#{get_mission.compact_name}/noauth/submission"
        if i < limit
          assert_response :unauthorized
        else
          assert_response :too_many_requests
        end
      end
    end
  end

  context "with different ip addresses" do
    let(:remote_addrs) { ["1.1.1.1", "2.2.2.2", "3.3.3.3"] * limit }

    it "should not apply" do
      (limit * 2).times do |i|
        get "/m/#{get_mission.compact_name}/formList", headers: { REMOTE_ADDR: remote_addrs[i] }
        assert_response :unauthorized
      end
    end
  end

  context "for sms requests under /m/mission_name", :sms do
    it "should not apply" do
      (limit + 1).times do |i|
        post "/m/#{get_mission.compact_name}/sms/submit/#{get_mission.setting.incoming_sms_token}",
          params: { from: 14045551212, body: "test", sent_at: Time.zone.now.strftime("%Q"), frontlinecloud: 1 }
        assert_response :ok
      end
    end
  end
end
