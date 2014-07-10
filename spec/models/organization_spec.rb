require 'spec_helper'

describe Organization do
  context "validations" do
    it "should not allow blank for name" do 
      @org = Organization.create(name: "", subdomain: "a_name_org")
      expect(@org).to have(1).errors_on(:name)
    end

    it "should not allow blank for subdomain" do 
      @org = Organization.create(name: "test", subdomain: "")
      expect(@org).to have(2).errors_on(:subdomain)
      expect(@org.errors.full_messages).to eql ["Subdomain: This field is required.", "Subdomain: is invalid"]
    end

    it "should not allow duplicates for name" do 
      @first = Organization.create(name: "a name", subdomain: "a_name_org")
      @second = Organization.create(name: "a name", subdomain: "a_name")
      expect(@second).to have(1).errors_on(:name)
    end

    it "should not allow duplicates for subdomain" do 
      @first = Organization.create(name: "a name", subdomain: "a_name")
      @second = Organization.create(name: "another name", subdomain: "a_name")
      expect(@second).to have(1).errors_on(:subdomain)
    end  
  end

  context "subdomain" do
    it "should allow - " do
      @org = Organization.create(name: "test", subdomain: "one-for-all")
      expect(@org.subdomain).to eq "one-for-all"
    end

    it "should allow _" do
      @org = Organization.create(name: "test", subdomain: "one_for_all")
      expect(@org.subdomain).to eq "one_for_all"
    end

    it "should allow numbers" do
      @org = Organization.create(name: "test", subdomain: "one_4_all")
      expect(@org.subdomain).to eq "one_4_all"
    end

    it "should convert to lowercase before save" do
      @org = Organization.create(name: "test", subdomain: "aweSOME")
      expect(@org.subdomain).to eq "awesome"
    end

    it "should not allow real subdomain www as compact name" do
       @org = Organization.create(name: "test", subdomain: "www")
       expect(@org).to have(1).error_on(:subdomain)
    end

    it "should not allow other punctuation besides - _" do
      @org = Organization.create(name: "one4all!!!")
      expect(@org).to have(2).errors_on(:subdomain)
      expect(@org.errors.full_messages).to eql ["Subdomain: This field is required.", "Subdomain: is invalid"]
    end

    it "should have message when a reserved word is used" do
       @org = Organization.create(name: "test", subdomain: "ssh")
       expect(@org.errors.full_messages.first).to eql "Subdomain: is reserved"
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
    it "the mission.organization_id and form.organization_id gets assigned when form is cloned" do
      org = FactoryGirl.create(:organization)
      mission = FactoryGirl.create(:mission, :name => 'missionOne', :organization => org)
      form = FactoryGirl.create(:form, mission: mission)
      form_dup = form.replicate(:mode => 'clone')
      expect(form.organization_id).to eql form_dup.organization_id
    end

    it "the form.mission_id is null and form.organization_id gets assigned when form is cloned" do
      org = FactoryGirl.create(:organization)
      form = FactoryGirl.create(:form, is_standard: true)
      form_dup = form.replicate(:mode => 'clone')
      expect(form_dup.mission_id).to be_nil
      expect(form.organization_id).to eql form_dup.organization_id
    end
  end 
  
end

