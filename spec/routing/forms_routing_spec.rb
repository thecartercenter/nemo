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

    describe "with locale" do

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

      it "recognizes and generates #add_questions" do
        { :post => "/en/forms/1/add_questions" }.should route_to(:controller => "forms", :action => "add_questions", :id => "1", "locale"=>"en")
      end

      it "recognizes and generates #remove_questions" do
        { :post => "/en/forms/1/remove_questions" }.should route_to(:controller => "forms", :action => "remove_questions", :id => "1", "locale"=>"en")
      end

      it "recognizes and generates #clone" do
        { :put => "/en/forms/1/clone" }.should route_to(:controller => "forms", :action => "clone", :id => "1", "locale"=>"en")
      end

      it "recognizes and generates #publish" do
        { :put => "/en/forms/1/publish" }.should route_to(:controller => "forms", :action => "publish", :id => "1", "locale"=>"en")
      end

      it "recognizes and generates #choose_questions" do
        { :get => "/en/forms/1/choose_questions" }.should route_to(:controller => "forms", :action => "choose_questions", :id => "1", "locale"=>"en")
      end

    end

    describe "for ODK" do

      describe "with shortened (/m)" do
        it "recognizes and generates #index xml" do
          { get: "/m/m_compact_name/formList" }.should route_to(controller: "forms", action: "index", :mission_compact_name => "m_compact_name", :format => :xml)
        end

        it "recognizes and generates #show xml" do
          { get: "/m/m_compact_name/forms/1" }.should route_to(controller: "forms", action: "show", :mission_compact_name => "m_compact_name", :id => "1", :format => :xml)
        end
      end

      describe "with full (/missions)" do
        it "recognizes and generates #index xml" do
          { get: "/missions/m_compact_name/formList" }.should route_to(controller: "forms", action: "index", :mission_compact_name => "m_compact_name", :format => :xml)
        end

        it "recognizes and generates #show xml" do
          { get: "/missions/m_compact_name/forms/1" }.should route_to(controller: "forms", action: "show", :mission_compact_name => "m_compact_name", :id => "1", :format => :xml)
        end
      end

    end

  end

end

