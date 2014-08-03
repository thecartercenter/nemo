require 'test_helper'

class ReplicationTest < ActiveSupport::TestCase

  test "#dest_mission will be nil when promoting an object" do
    setup_replication_object(:mode => :promote)
    assert_equal(nil, @ro.dest_mission)
  end

  test "#dest_mission will use the src_mission when we are not promoting an object" do
    setup_replication_object(:mode => :clone)
    assert_equal(SRC_OBJ_MISSION, @ro.dest_mission)
  end

  test "#dest_mission will use the mission parameter when we are copying to a mission" do
    setup_replication_object(:mode => :to_mission, :dest_mission => "new mission")
    assert_equal("new mission", @ro.dest_mission)
  end

  test "#to_standard? is true if the to_mission is nil" do
    setup_replication_object(:mode => :clone, :src_obj => {:mission => nil, :is_standard? => true})
    assert_equal(true, @ro.to_standard?)
  end

  test "#to_standard? is false if the to_mission is not nil" do
    setup_replication_object(:mode => :to_mission, :dest_mission => "some mission", :src_obj => {:mission => "something", :is_standard? => true})
    assert_equal(false, @ro.to_standard?)
  end

  # test set up
  SRC_OBJ_MISSION = "some mission"
  def setup_replication_object(options={})
    mode = options[:mode]
    src_obj_options = options[:src_obj] ||= {}

    # give the fake src_obj a mission, unless one was given
    src_obj_options[:mission] ||= SRC_OBJ_MISSION unless src_obj_options.key?(:mission)

    src_obj = stub(src_obj_options)
    @ro = Replication.new(:mode => mode, :dest_mission => options[:dest_mission], :src_obj => src_obj)
  end
end

