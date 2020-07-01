# frozen_string_literal: true

require "rails_helper"

describe "basic authentication for xml requests" do
  let(:form_list) { "/m/#{get_mission.compact_name}/formList" }

  before do
    @user = create(:user)
  end

  context "when not already logged in" do
    # `fooé:bar` base64 encoded with Latin-1 output (instead of UTF-8).
    let(:bad_headers) { {"HTTP_AUTHORIZATION" => "Basic Zm9v6TpiYXI="} }

    it "should be required" do
      get form_list
      assert_response :unauthorized
      expect(response.headers["WWW-Authenticate"]).to eq('Basic realm="Application"')
    end

    it "should gracefully handle invalid Latin-1 encoding" do
      get form_list, headers: bad_headers
      assert_response :unauthorized
      expect(response.headers["WWW-Authenticate"]).to eq('Basic realm="Application"')
    end
  end

  context "when already logged in via web" do
    before do
      login(@user)
    end

    it "should not be required" do
      get form_list
      assert_response :success
    end
  end
end
