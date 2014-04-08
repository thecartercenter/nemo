require "spec_helper"

describe WelcomeController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/" }.should route_to(controller: "welcome", action: "index")
    end

    it "with locale, recognizes and generates #index" do
      { :get => "/en" }.should route_to(controller: "welcome", action: "index", :locale => "en")
    end

    it "with locale in admin_mode, recognizes and generates #index" do
      { :get => "/en/admin" }.should route_to(controller: "welcome", action: "index", :locale => "en", :admin_mode => "admin")
    end

    it "recognizes and generates #info_window" do
      { :get => "/info_window" }.should route_to(:controller => "welcome", :action => "info_window")
    end

    it "recognizes and generates #report_update" do
      { :get => "/report_update/2" }.should route_to(:controller => "welcome", :action => "report_update", :id => "2")
    end

  end
end

