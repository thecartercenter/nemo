require "spec_helper"

describe UserSessionsController do
  describe "routing" do

    it "recognizes and generates #logged_out" do
      { :get => "/logged_out" }.should route_to(controller: "user_sessions", action: "logged_out")
    end

    it "recognizes and generates #destroy" do
      { :get => "/logout" }.should route_to(controller: "user_sessions", action: "destroy")
    end

    it "recognizes and generates #new" do
      { :get => "/login" }.should route_to(controller: "user_sessions", action: "new")
    end

    describe "with locale" do
      it "recognizes and generates #logged_out" do
        { :get => "/en/logged_out" }.should route_to(controller: "user_sessions", action: "logged_out", :locale => "en")
      end

      it "recognizes and generates #destroy" do
        { :get => "/en/logout" }.should route_to(controller: "user_sessions", action: "destroy", :locale => "en")
      end

      it "recognizes and generates #new" do
        { :get => "/en/login" }.should route_to(controller: "user_sessions", action: "new", :locale => "en")
      end
    end

  end
end

