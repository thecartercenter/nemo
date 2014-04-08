require "spec_helper"

describe MissionsController do
  describe "routing" do
    describe "with locale and admin" do

      it "recognizes and generates #index" do
        { get: "/en/admin/missions" }.should route_to(controller: "missions", action: "index", "locale"=>"en", :admin_mode => "admin")
      end

      it "recognizes and generates #create" do
        { :post => "/en/admin/missions" }.should route_to(:controller => "missions", :action => "create", "locale"=>"en", :admin_mode => "admin")
      end

      it "recognizes and generates #new" do
        { :get => "/en/admin/missions/new" }.should route_to(:controller => "missions", :action => "new", "locale"=>"en", :admin_mode => "admin")
      end

      it "recognizes and generates #show" do
        { :get => "/en/admin/missions/1" }.should route_to(:controller => "missions", :action => "show", :id => "1", "locale"=>"en", :admin_mode => "admin")
      end

    end
  end
end

