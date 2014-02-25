require 'test_helper'

# tests for standardizable functionality as applied to option sets
class StandardizableOptionSetTest < ActiveSupport::TestCase

  test "std option set should have std optionings and options" do
    os = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
    assert(os.reload.optionings.all?(&:is_standard?))
    assert(os.options.all?(&:is_standard?))
    assert(os.optionings.all?(&:is_standard?))
  end

  test "adding options to an std option set should create std options and optionings" do
    f = FactoryGirl.create(:option_set, :is_standard => true)
    f.options << FactoryGirl.create(:option, :is_standard => true)
    assert(f.reload.options.all?(&:is_standard?))
    assert(f.optionings.all?(&:is_standard?))
  end

  test "replicating option set within mission should avoid name conflict" do
    os = FactoryGirl.create(:option_set, :name => "Stuff")
    os2 = os.replicate(:mode => :clone)

    assert_not_equal(os.id, os2.id)
    assert_equal("Stuff 2", os2.name)
  end

  test "replicating standard option set to mission should not change name if no matching exists" do
    os = FactoryGirl.create(:option_set, :name => "Stuff", :is_standard => true)
    assert_nil(os.mission)

    # make sure no matching set in mission
    assert_equal([], get_mission.option_sets.where(:name => 'Stuff'))

    # replicate and check name
    os2 = os.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal("Stuff", os2.name)

    # subsequent updates to std set should not perturb name
    os.optionings[0].rank = 2
    os.optionings[1].rank = 1
    os.save!
    assert_equal('Stuff', os2.reload.name)
  end

  test "replicating standard option set to mission should change name if matching set exists in mission" do
    std = FactoryGirl.create(:option_set, :name => 'Stuff', :is_standard => true)
    orig = FactoryGirl.create(:option_set, :name => 'Stuff')
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal('Stuff 2', copy.name)
  end

  test "replicating non-standard option set within mission should not duplicate options" do
    os = FactoryGirl.create(:option_set, :name => "Stuff")
    os2 = os.replicate(:mode => :clone)

    assert_not_equal(os.id, os2.id)
    assert_equal(os.mission, os2.mission)
    assert_not_equal(os.optionings, os2.optionings)
    assert_equal(os.options, os2.options)

    # make sure still ok after reload
    os2.reload
    assert_equal(os.options, os2.options)
  end

  test "replicating standard option set to mission should also replicate options" do
    std = FactoryGirl.create(:option_set, :name => "Stuff", :is_standard => true)

    # make sure options are also standard
    assert(std.options.first.is_standard?, 'options should be standard')

    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # options should be different
    assert_not_equal(std.options, copy.options)
    assert(!copy.options.include?(std.options.first), 'copied options should not include any originals')

    # copied objects should retain standard links
    assert_equal(copy.standard, std)
    assert_equal(copy.options.first.standard, std.options.first)
    assert_equal(copy.optionings.first.standard, std.optionings.first)

    # copies should not be standard
    assert(!copy.is_standard?, 'copy should not be standard')
    assert(!copy.optionings.first.is_standard?, 'copy should not be standard')
    assert(!copy.options.first.is_standard?, 'copy should not be standard')
  end

  test "replicating should not copy options if they have already been copied from earlier replication" do
    # create two standard option sets sharing an option
    std1 = FactoryGirl.create(:option_set, :name => "Stuff", :is_standard => true, :option_names => %w(yes no))
    std2 = FactoryGirl.create(:option_set, :name => "Stuff2", :is_standard => true, :option_names => %w(maybe))
    std2.options << std1.options.first
    std2.save!

    # ensure the option is shared
    assert_equal(std1.options[0], std2.options[1])

    # replicate std1 to a mission then replicate std2
    copy1 = std1.replicate(:mode => :to_mission, :mission => get_mission)
    copy2 = std2.replicate(:mode => :to_mission, :mission => get_mission)

    # the maybe option should be copied but the yes option should not be copied twice
    assert_equal(3, get_mission.options.size)
    assert_equal(copy1.options[0], copy2.options[1])

    # copied options should be distinct
    assert_not_equal(copy1.options[0], std1.options[0])

    # copies should have appropriate standard links
    assert_equal(std1.options[0], copy1.options[0].standard)
  end

  test "changing name of option set with copies should avoid conflicts when changing name of copies" do
    # make set and copy
    std = FactoryGirl.create(:option_set, :name => 'Stuff', :is_standard => true)
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # make regular set in a mission
    reg = FactoryGirl.create(:option_set, :name => 'Fluff', :mission => get_mission)

    # rename std to same name as reg
    std.name = 'Fluff'
    std.save!
    copy.reload

    # copy's name should be Fluff 2 to avoid conflict
    assert_equal('Fluff 2', copy.name)
  end

  test "adding new option to existing std option set should also add it to copies" do
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)
    # add option
    std.options << FactoryGirl.create(:option, :name => 'maybe', :is_standard => true)
    std.save!
    assert_equal(3, std.options.size)

    # copy should have new option also
    copy.reload
    assert_equal(3, copy.options.size)
    assert_equal(%w(yes no maybe), copy.options.map(&:name))
  end

  test "adding existing std option to existing std option set should also add it to copies" do
    # create two sets and replicate both
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)
    std2 = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(high low))
    copy2 = std2.replicate(:mode => :to_mission, :mission => get_mission)

    # now add an option from one to the other
    std.options << std2.options[0]
    std.save!
    assert_equal(std.options[2], std2.options[0])

    # copy should have new option also
    copy.reload
    assert_equal(3, copy.options.size)
    assert_equal(copy.options[2], copy2.options[0])
  end

  test "removing optioning from std option set will also remove from copies" do
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # remove option
    std.optionings.destroy(std.optionings[2])
    std.save!
    std.reload
    assert_equal(2, std.options.size)

    # ensure option is deleted from copy
    copy.reload
    assert_equal(2, copy.options.size)
    assert_equal(%w(yes no), copy.options.map(&:name))
  end

  test "deleting an option set should delete copies" do
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # make sure optionings exist
    assert_not_nil(Optioning.where(:option_set_id => copy.id).first)

    std.destroy

    # make sure option set and optionings are destroyed
    assert(!OptionSet.exists?(copy))
    assert_nil(Optioning.where(:option_set_id => copy.id).first)
  end

  test "is_standard param should be cascaded down on save" do
    # manually construct option set so factory doesnt interfere
    os = OptionSet.new(:name => 'foo', :is_standard => true)
    os.optionings.build(:rank => 1)
    os.optionings[0].build_option(:name => 'Yes')

    # check that child is_standard is not set before save
    assert(!os.optionings[0].is_standard?)
    assert(!os.optionings[0].option.is_standard?)

    # save and check cascade
    os.save!
    os.reload
    assert(os.optionings[0].is_standard?)
    assert(os.optionings[0].option.is_standard?)
  end

  test "deleting option from std option set with copies should replicate properly" do
    # setup std option set, question, and form
    std_os = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
    std_q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => std_os, :is_standard => true)
    std_f = FactoryGirl.create(:form, :is_standard => true)
    std_f.questions << std_q

    # make copy of form, which will copy option set also
    # we do it this way because it produced a bug, whereas just replicating the option set without the form did not
    copy_f = std_f.replicate(:mode => :to_mission, :mission => get_mission)

    # get a reference to the copied option set and ensure it's different from the std
    copy_os = copy_f.questions.last.option_set
    assert_not_equal(copy_os, std_os)

    # remove option from std set
    std_os.optionings[1].destroy

    # copy should now have only two options -- yes and maybe
    assert_equal(%w(yes maybe), copy_os.reload.options.map(&:name))
  end

  test "user-modifiable field should be replicated on create" do
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal('yes', copy.options.first.name)
  end

  test "user-modifiable attrib should not be replicated on update" do
    std = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no))
    copy = std.replicate(:mode => :to_mission, :mission => get_mission)

    # modify an option name
    copy.options.first.update_attributes!(:name => 'maybe')

    # re-replicate
    std.reload.replicate(:mode => :to_mission, :mission => get_mission)

    # option name should still be maybe
    assert_equal('maybe', copy.reload.options.first.name)
  end

end
