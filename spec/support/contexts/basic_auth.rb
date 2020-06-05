# frozen_string_literal: true

shared_context "basic auth" do
  let(:auth_header) { {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)} }
end
