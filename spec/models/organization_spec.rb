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

end

