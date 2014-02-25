require 'test_helper'

# tests for standardizable functionality as applied to questions
class StandardizableQuestionTest < ActiveSupport::TestCase

  test "replicating a question within a mission should change the code" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo')
    q2 = q.replicate(:mode => :clone)
    assert_equal('Foo2', q2.code)
    q3 = q2.replicate(:mode => :clone)
    assert_equal('Foo3', q3.code)
    q4 = q3.replicate(:mode => :clone)
    assert_equal('Foo4', q4.code)
  end

  test "replicating a standard question should not change the code" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo', :is_standard => true)
    q2 = q.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal(q.code, q2.code)
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'Foo1', :is_standard => true)
    q2 = q.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal(q.code, q2.code)
  end

  test "replicating a question should not replicate the key field" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :key => true)
    q2 = q.replicate(:mode => :clone)

    assert_not_equal(q, q2)
    assert_not_equal(q.key, q2.key)
  end

  test "replicating a select question within a mission should not replicate the option set" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one')
    q2 = q.replicate(:mode => :clone)
    assert_not_equal(q, q2)
    assert_equal(q.option_set, q2.option_set)
  end

  test "replicating a standard select question should replicate the option set" do
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :is_standard => true)

    # ensure the std q looks right
    assert_nil(q.mission)
    assert_nil(q.option_set.mission)
    assert(q.option_set.is_standard)

    # replicate and test
    q2 = q.replicate(:mode => :to_mission, :mission => get_mission)
    assert_not_equal(q, q2)
    assert_not_equal(q.option_set, q2.option_set)
    assert_not_equal(q.option_set.options.first, q2.option_set.options.first)
    assert_not_nil(q2.option_set.mission)
  end

  test "replicating question with short code that ends in zero should work" do
    q = FactoryGirl.create(:question, :qtype_name => 'integer', :code => 'q0')
    q2 = q.replicate(:mode => :clone)
    assert_equal('q1', q2.code)
  end

  test "name should be replicated on create" do
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    q2 = q.replicate(:mode => :to_mission, :mission => get_mission)
    assert_equal('Foo', q2.name)

    # also test _name attrib
    assert_equal('Foo', q2._name)
  end

  test "name should be replicated on update if copy hasnt changed" do
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    q2 = q.replicate(:mode => :to_mission, :mission => get_mission)
    q.name = 'Bar'
    q.save!
    assert_equal('Bar', q2.reload.name)

    # also test _name attrib
    assert_equal('Bar', q2._name)
  end

  test "name should not be replicated on update if copy has changed" do
    other_mission = FactoryGirl.create(:mission, :name => 'other')
    q = FactoryGirl.create(:question, :is_standard => true, :name => 'Foo')
    copy1 = q.replicate(:mode => :to_mission, :mission => get_mission)
    copy2 = q.replicate(:mode => :to_mission, :mission => other_mission)

    # change copy1
    copy1.name = 'Baz'
    copy1.save!

    # now change std -- change should not replicate to copy1
    q.reload.name = 'Bar'
    q.save!
    assert_equal('Baz', copy1.reload.name)
    assert_equal('Bar', copy2.reload.name)

    # also test _name attrib
    assert_equal('Baz', copy1.reload._name)
    assert_equal('Bar', copy2.reload._name)
  end

  test "only translations that have not changed in copy should be replicated on update" do
    q = FactoryGirl.create(:question, :is_standard => true, :name_en => 'Cow', :name_fr => 'Vache')
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)

    # change french translation on copy
    copy.name_fr = 'Vachon'
    copy.save!

    # now change the english translation on the std
    q.name_en = 'Cowed'
    q.save!

    # english should be replicated but french should not
    assert_equal('Cowed', copy.reload.name_en)
    assert_equal('Vachon', copy.name_fr)
  end

  test "translation delete should be replicated if copy translation has not deviated" do
    q = FactoryGirl.create(:question, :is_standard => true, :name_en => 'Cow', :name_fr => 'Vache')
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)

    # delete french translation without any changes to copy
    q.name_fr = nil
    q.save!

    # delete should be replicated
    assert_equal('Cow', copy.reload.name_en)
    assert_nil(copy.reload.name_fr)
  end

  test "translation delete should not be replicated if copy translation has deviated" do
    q = FactoryGirl.create(:question, :is_standard => true, :name_en => 'Cow', :name_fr => 'Vache')
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)

    # change copy first
    copy.name_fr = 'Vachon'
    copy.save!

    # delete std french translation
    q.reload.name_fr = nil
    q.save!

    # delete should not be replicated
    assert_equal('Cow', copy.reload.name_en)
    assert_equal('Vachon', copy.reload.name_fr)
  end

  test "translation delete should be replicated if copy translation also been deleted" do
    q = FactoryGirl.create(:question, :is_standard => true, :name_en => 'Cow', :name_fr => 'Vache')
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)

    # delete copy translation first
    copy.name_fr = nil
    copy.save!

    # delete std translation
    q.reload.name_fr = nil
    q.save!

    # delete should be intact
    assert_equal('Cow', copy.reload.name_en)
    assert_equal(nil, copy.reload.name_fr)
  end

  test "replication of obj with nil hash value should work" do
    # make question with no names
    q = FactoryGirl.create(:question, :is_standard => true)
    q.name_translations = nil
    q.save!

    assert_nil(q.reload.name_translations)

    # replication should work
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)
    assert_nil(copy.name_translations)
  end

  test "change of hash value to nil should be replicated if no changes to copy" do
    q = FactoryGirl.create(:question, :is_standard => true, :name_en => 'Cow', :name_fr => 'Vache')
    copy = q.replicate(:mode => :to_mission, :mission => get_mission)

    # change std hash value to nil
    q.name_translations = nil
    q.save!

    # copy value should now be nil
    assert_nil(copy.reload.name_translations)
  end

end
