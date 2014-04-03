require "spec_helper"

describe FormsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { get: "/forms" }.should route_to(controller: "forms", action: "index")
    end

    it "recognizes and generates #create" do
      { :post => "/forms" }.should route_to(:controller => "forms", :action => "create")
    end

    it "recognizes and generates #new" do
      { :get => "/forms/new" }.should route_to(:controller => "forms", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/forms/1" }.should route_to(:controller => "forms", :action => "show", :id => "1")
    end

    describe "with local" do

      it "recognizes and generates #index" do
        { get: "/en/forms" }.should route_to(controller: "forms", action: "index", "locale"=>"en")
      end

      it "recognizes and generates #create" do
        { :post => "/en/forms" }.should route_to(:controller => "forms", :action => "create", "locale"=>"en")
      end

      it "recognizes and generates #new" do
        { :get => "/en/forms/new" }.should route_to(:controller => "forms", :action => "new", "locale"=>"en")
      end

      it "recognizes and generates #show" do
        { :get => "/en/forms/1" }.should route_to(:controller => "forms", :action => "show", :id => "1", "locale"=>"en")
      end

    end

  end

end

