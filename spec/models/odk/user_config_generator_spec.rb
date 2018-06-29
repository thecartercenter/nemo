require 'rails_helper'

module ODK
  describe ODK::UserConfigEncoder do
    describe "#encode_config" do
      it "returns correct encoding" do
        test_username = "test_user"
        test_pwd = "test_pwd"
        site_url = "https://secure.cceom.org/m/kenya2017"
        #expected = '{"general":{"password":"test_pwd","username":"test_user","server_url":"https://secure.cceom.org/m/kenya2017"},"admin":{}}'
        #actual = ODKConfigGenerator.new().generate_string(test_username, test_pwd, site_url)

        # testing
        actual_encoding = ODK::UserConfigEncoder.new(test_username, test_pwd, site_url).encode_config
        expected_encoding = "eJw1jTsKwzAUBO+ytbGSNAFdxghpsUOsD+9JMcHo7laKNAM7sMyJlYnidtgTxakeWQIsKrUu5QiY0JSSXOTf/vbQgx/K0mRcsdVa1Bqj9E04e88c5yyriebN9HWP2/2JPsGF+Eoj1fsFSTkqpA=="
        expect(actual_encoding).to eq expected_encoding
      end
    end
  end
end
