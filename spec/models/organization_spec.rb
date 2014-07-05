require 'spec_helper'

describe Organization do

  context "validations" do

    it "should not allow blank for name" do 
      @org = Organization.create(name: "", compact_name: "a_name_org")
      expect(@org).to have(1).errors_on(:name)
    end

    it "should not allow duplicates for name" do 
      @first = Organization.create(name: "a name", compact_name: "a_name_org")
      @second = Organization.create(name: "a name", compact_name: "a_name")
      expect(@second).to have(1).errors_on(:name)
    end

    it "should not allow duplicates for compact_name" do 
      @first = Organization.create(name: "a name", compact_name: "a_name")
      @second = Organization.create(name: "another name", compact_name: "a_name")
      expect(@second).to have(1).errors_on(:compact_name)
    end  
  end

  context "compact_name" do

    it "should make a compact_name from the name as default" do
      @org = Organization.create(name: "Help a Friend")
      expect(@org.compact_name).to eq "helpafriend"
    end

    it "should remove punctuation & to make compact_name" do
      @org = Organization.create(name: "You & Myself")
      expect(@org.compact_name).to eq "youmyself"
    end

    it "should remove punctuation ' to make compact_name" do
      @org = Organization.create(name: "Able's Group")
      expect(@org.compact_name).to eq "ablesgroup"
    end

    it "should remove punctuation \" to make compact_name" do
      @org = Organization.create(name: "Let \"Every one\" Help")
      expect(@org.compact_name).to eq "leteveryonehelp"
    end

    it "should not allow real subdomain www as compact name" do
       @org = Organization.create(name: "test", compact_name: "www")
       expect(@org).to have(1).error_on(:compact_name)
    end

    it "should not allow real subdomain docs as compact name" do
       @org = Organization.create(name: "test", compact_name: "docs")
       expect(@org).to have(1).error_on(:compact_name)
    end

    it "should not allow real subdomain ssh as compact name and have message" do
       @org = Organization.create(name: "test", compact_name: "ssh")
       expect(@org).to have(1).error_on(:compact_name)
       expect(@org.errors.full_messages.first).to eql "Compact name: is reserved"
    end

  end


  context "relationships" do
    before do
      @org = FactoryGirl.create(:organization)
      @mission1 = FactoryGirl.create(:mission, :name => 'missionOne', :organization => @org)
      @mission2 = FactoryGirl.create(:mission, :name => 'missionTwo', :organization => @org)
    end

    it "an organization can have 1 or more missions" do 
      expect(@org.missions.count).to eql 2
    end

    it "mission has one organization" do
      expect(@mission1.organization).to eql @org
    end
  end


  context "replication" do

    it "the organization_id gets assigned to the mission when form is cloned" do
      org = FactoryGirl.create(:organization)
      mission = FactoryGirl.create(:mission, :name => 'missionOne', :organization => org)
      form = FactoryGirl.create(:form, mission: mission)
      form_dup = form.replicate(:mode => 'clone')
      expect(form.mission.organization_id).to eql form_dup.mission.organization_id
    end

  end
  
end

