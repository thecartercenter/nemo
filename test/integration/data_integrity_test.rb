require 'test_helper'

class DataIntegrityTest < ActionDispatch::IntegrationTest
  include PathHelper

  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    login(@admin)
  end

  test "unpublished form should be deletable" do
    form = FactoryGirl.create(:form)
    assert_action_link(form, :destroy, true)
    assert_deletable(form)
  end

  test "published form should not be deletable" do
    form = FactoryGirl.create(:form)

    # publish and make sure it's published
    form.publish!
    assert(form.reload.published?)

    assert_action_link(form, :destroy, false)
  end

  test "form with responses should not be deletable" do
    form = FactoryGirl.create(:form)
    FactoryGirl.create(:response, :form => form)

    assert_action_link(form, :destroy, false)
  end

  test "standard form copy should be deletable" do
    form = FactoryGirl.create(:form, :is_standard => true)
    copy = form.replicate(:mode => :to_mission, :dest_mission => get_mission)
    assert_action_link(copy, :destroy, true)
    assert_deletable(copy)
  end

  test "published form should be renameable" do
    form = FactoryGirl.create(:form)
    form.publish!

    assert_field_changeable(form, :name)
  end

  test "should not be able to add non-required question to published form" do
    form = FactoryGirl.create(:form)
    form.publish!

    # check for no add question link
    get(form_path(form, :mode => 'm', :mission_name => get_mission.compact_name))
    assert_response(:success)
    assert_select("a[href$=choose_questions]", false)
  end

  # DID NOT FINISH WRITING ALL THESE TESTS DUE TO TIME CONSTRAINTS

  private
    def assert_action_link(obj, action, tf)
      # Load the index view for the object
      get(dynamic_path(obj, action: :index, mode: 'm', mission_name: obj.mission.compact_name))
      assert_response(:success)
      assert_select("tr##{obj.class.model_name.singular}_#{obj.id} a.action_link_#{action}", tf)
    end

    def assert_deletable(obj)
      # do delete
      delete(send("#{obj.class.model_name.singular}_path", obj, :mode => 'm', :mission_name => obj.mission.compact_name))

      assert_successful_action(obj)

      # ensure object was deleted
      assert(!obj.class.exists?(obj))
    end

    def assert_field_changeable(obj, field)
      singular = obj.class.model_name.singular
      get(send("edit_#{singular}_path", obj, :mode => 'm', :mission_name => obj.mission.compact_name))
      assert_response(:success)
      assert_select("input##{singular}_#{field}")
      new_val = "new val #{rand(100000000)}"
      put(send("#{singular}_path", obj), singular => {field => new_val})
      follow_redirect!
      assert_equal(new_val, obj.reload.send(field))
    end

    def assert_successful_action(obj)
      # ensure no errors
      follow_redirect!
      assert_response(:success)
      assert(obj.errors.empty?)
      assert_nil(flash[:error])
      assert_nil(assigns(:error_msg))
    end
end