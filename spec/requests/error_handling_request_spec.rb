require "rails_helper"

describe "error handling" do
  let(:user) { create(:user, admin: true) }
  let(:mission) { get_mission }

  it "renders 400 when a POST request is sent with no params" do
    post(reports_path(mission_name: mission.compact_name, mode: "m"))
    expect(response).not_to be_success
    expect(response).to have_http_status 400
  end
end
