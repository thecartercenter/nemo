# Holds specs for methods common to all replicable classes.
require 'spec_helper'

describe Replicable do
  describe "attrib_before_save" do
    it "should work for changed attribs" do
      q = FactoryGirl.create(:question, :code => 'Alpha')
      q.code = 'Bravo'
      q.save!
      assert_equal('Alpha', q.attrib_before_save(:code))
    end

    it "should work for unchanged attribs on update" do
      q = FactoryGirl.create(:question, :code => 'Alpha')

      # change some other attribute
      q.minimum = 5
      q.save!

      # code should not be in previous_changes but the method should work anyway
      assert(!q.previous_changes.has_key?('code'))
      assert_equal('Alpha', q.attrib_before_save(:code))
    end

    it "should return initial value on create" do
      q = FactoryGirl.create(:question, :code => 'Alpha')
      assert_equal('Alpha', q.attrib_before_save(:code))
    end
  end
end
