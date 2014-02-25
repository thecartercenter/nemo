require 'test_helper'

class ReplicationTest < ActiveSupport::TestCase

  test "#determine_dest_mission will be nil when promoting an object" do
    setup_replication_object(:mode => :promote)
    assert_equal(nil, @ro.determine_dest_mission)
  end

  test "#determine_dest_mission will use the src_mission when we are not promoting an object" do
    setup_replication_object(:mode => :clone)
    assert_equal(SRC_OBJ_MISSION, @ro.determine_dest_mission)
  end

  test "#determine_dest_mission will use the mission parameter when we are copying to a mission" do
    setup_replication_object(:mode => :to_mission, :mission => "new mission")
    assert_equal("new mission", @ro.determine_dest_mission)
  end


  test "#replicating_to_standard? is true if the to_mission is nil" do
    setup_replication_object(:mode => :clone, :src_obj => {:mission => nil, :is_standard? => true})
    assert_equal(true, @ro.replicating_to_standard?)
  end

  test "#replicating_to_standard? is false if the to_mission is not nil" do
    setup_replication_object(:mode => :to_mission, :to_mission => "some mission", :src_obj => {:mission => "something", :is_standard? => true})
    assert_equal(false, @ro.replicating_to_standard?)
  end


  test "replicating and promoting a form should do a deep copy" do
    f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => false)
    f2 = f.replicate(:mode => :promote)

    # mission should now be set and should not be standard
    assert(f2.is_standard, "Newly promoted form is should be a standard type.")
    assert_equal(nil, f2.mission)

    # all objects should be distinct
    assert_not_equal(f, f2)
    assert_not_equal(f.questionings[0], f2.questionings[0])
    assert_not_equal(f.questionings[0].question, f2.questionings[0].question)
    assert_not_equal(f.questionings[0].question.option_set, f2.questionings[0].question.option_set)
    assert_not_equal(f.questionings[0].question.option_set.optionings[0], f2.questionings[0].question.option_set.optionings[0])
    assert_not_equal(f.questionings[0].question.option_set.optionings[0].option, f2.questionings[0].question.option_set.optionings[0].option)

    # but properties should be same
    assert_equal(f.questionings[0].rank, f2.questionings[0].rank)
    assert_equal(f.questionings[0].question.code, f2.questionings[0].question.code)
    assert_equal(f.questionings[0].question.option_set.optionings[0].option.name, f2.questionings[0].question.option_set.optionings[0].option.name)
  end


  # test set up
  SRC_OBJ_MISSION = "some mission"
  def setup_replication_object(options={})
    mode = options[:mode]
    src_obj_options = options[:src_obj] ||= {}
    src_obj_options[:mission] ||= SRC_OBJ_MISSION unless src_obj_options.key?(:mission)
    src_obj = stub(src_obj_options)
    @ro = Replication.new(:mode => mode, :mission => options[:mission], :src_obj => src_obj)
  end
end

