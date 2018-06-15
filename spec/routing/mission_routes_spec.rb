require "rails_helper"

describe "router" do
  it "routes broadcasts with locale and prefix" do
    expect(get: "/en/m/mission123/broadcasts").to route_to(
      controller: "broadcasts", action: "index", locale: "en", mode: "m", mission_name: "mission123")
  end

  it "rejects invalid mission name" do
    expect(get: "/en/m/mission!123/broadcasts").not_to be_routable
  end

  it "rejects admin prefix" do
    expect(get: "/en/admin/mission123/broadcasts").not_to be_routable
  end

  it "doesnt route normal path without explicit locale" do
    expect(get: "/m/mission123/broadcasts").not_to be_routable
  end

  it "routes with report namespace" do
    expect(get: "/en/m/mission123/reports").to route_to(
      controller: "reports", action: "index", locale: "en", mode: "m", mission_name: "mission123")
  end

  it "routes special info-window route" do
    expect(get: "/en/m/mission123/info-window").to route_to(
      controller: "welcome", action: "info_window", locale: "en", mode: "m", mission_name: "mission123")
  end

  it "routes mission root" do
    # Note this will also route a mistaken URL like /en/m/broadcasts, but that's the expected behavior
    expect(get: "/en/m/mission123").to route_to(
      controller: "welcome", action: "index", locale: "en", mode: "m", mission_name: "mission123")
  end

  it "rejects if missing mission and prefix" do
    expect(get: "/en/broadcasts").not_to be_routable
  end

  it "rejects if missing locale, mission and prefix" do
    expect(get: "/broadcasts").not_to be_routable
  end

  it "routes import standard" do
    expect(post: "/en/m/mission123/option-sets/import-standard").to route_to(
      controller: "option_sets", action: "import_standard", locale: "en",
      mode: "m", mission_name: "mission123")
  end

  it "routes ODK form list", :odk do
    expect(get: "/m/mission123/formList").to route_to(
      controller: "forms", action: "index", mode: "m", mission_name: "mission123", format: "xml", direct_auth: "basic")
  end

  it "routes ODK form download", :odk do
    expect(get: "/m/mission123/forms/99").to route_to(
      controller: "forms", action: "show", mode: "m", mission_name: "mission123",
      id: "99", format: "xml", direct_auth: "basic")
  end

  it "routes ODK submission", :odk do
    expect(post: "/m/mission123/submission").to route_to(
      controller: "responses", action: "create", mode: "m", mission_name: "mission123",
      format: "xml", direct_auth: "basic")
  end

  it "rejects ODK submission without mission", :odk do
    expect(post: "/submission").not_to be_routable
  end
end
