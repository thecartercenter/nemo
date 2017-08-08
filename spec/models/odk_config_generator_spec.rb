require 'spec_helper'

describe ODKConfigGenerator do
  describe "#generate_string" do
    it "returns valid json string" do
      test_username = "test_user"
      test_pwd = "test_pwd"
      site_url = "https://secure.cceom.org/m/kenya2017"
      expected = '{"general":{"password":"test_pwd","username":"test_user","server_url":"https:\/\/secure.cceom.org\/m\/kenya2017"},"admin":{}}'
      actual = ODKConfigGenerator.new().generate_string(test_username, test_pwd, site_url)

      expect(actual).to eq expected
    end
  end

  describe "#generate_odk_config" do
    it "calls generate_string" do
      subject = ODKConfigGenerator.new()
      expect(subject).to receive(:generate_string).and_return("string")

      subject.generate_odk_config("test", "test", "test")
    end

    it "deflates a string" do
      expect(Zlib::Deflate).to receive(:deflate).and_return(Zlib::Deflate.deflate("string"))

      ODKConfigGenerator.new().generate_odk_config("test", "test", "test")
    end

    it "encodes the string" do
      return_value = Base64.strict_encode64(Zlib::Deflate.deflate("string"))
      expect(Base64).to receive(:strict_encode64).and_return(return_value)

      ODKConfigGenerator.new().generate_odk_config("test", "test", "test")
    end
  end
end
