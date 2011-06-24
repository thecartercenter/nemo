require 'test_helper'

class PlaceTest < ActiveSupport::TestCase
  test "state/prov must have container" do
    p = Place.new(:long_name => "foo", :place_type_id => PlaceType.find_by_level(2).id)
    p.save
    assert(!p.valid?)
  end
end
