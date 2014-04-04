require "spec_helper"

describe MarkersController do
  describe "routing" do

    it "recognizes and generates #index" do
      { get: "/markers" }.should route_to(controller: "markers", action: "index")
    end

    it "recognizes and generates #create" do
      { :post => "/markers" }.should route_to(:controller => "markers", :action => "create")
    end

    it "recognizes and generates #new" do
      { :get => "/markers/new" }.should route_to(:controller => "markers", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/markers/1" }.should route_to(:controller => "markers", :action => "show", :id => "1")
    end

    describe "with locale" do

      it "recognizes and generates #index" do
        { get: "/en/markers" }.should route_to(controller: "markers", action: "index", "locale"=>"en")
      end

      it "recognizes and generates #create" do
        { :post => "/en/markers" }.should route_to(:controller => "markers", :action => "create", "locale"=>"en")
      end

      it "recognizes and generates #new" do
        { :get => "/en/markers/new" }.should route_to(:controller => "markers", :action => "new", "locale"=>"en")
      end

      it "recognizes and generates #show" do
        { :get => "/en/markers/1" }.should route_to(:controller => "markers", :action => "show", :id => "1", "locale"=>"en")
      end

      describe "with admin mode" do

        it "recognizes and generates #index" do
          { get: "/en/admin/markers" }.should route_to(controller: "markers", action: "index", "locale"=>"en", admin_mode: "admin")
        end

        it "recognizes and generates #create" do
          { :post => "/en/admin/markers" }.should route_to(:controller => "markers", :action => "create", "locale"=>"en", admin_mode: "admin")
        end

        it "recognizes and generates #new" do
          { :get => "/en/admin/markers/new" }.should route_to(:controller => "markers", :action => "new", "locale"=>"en", admin_mode: "admin")
        end

        it "recognizes and generates #show" do
          { :get => "/en/admin/markers/1" }.should route_to(:controller => "markers", :action => "show", :id => "1", "locale"=>"en", admin_mode: "admin")
        end

      end

    end

  end

end

