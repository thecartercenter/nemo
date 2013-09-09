require 'test_helper'
 
class AuthorizationTest < ActionDispatch::IntegrationTest
  
  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    login(@admin)
  end

  test "unpublished form should be deletable" do
    form = FactoryGirl.create(:form)
    assert_action_link(form, :destroy, true)
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
    copy = form.replicate(get_mission)
    assert_action_link(copy, :destroy, true)
  end

  test "published form should be renameable" do
    form = FactoryGirl.create(:form)
    form.publish!

    get(edit_form_path(form))
    assert_select('input#form_name')
    put(form_path(form), :form => {:name => 'new name'})
    follow_redirect!
    assert_equal('new name', form.reload.name)
  end

  private
    def assert_action_link(obj, action, tf)
      get(send("#{obj.class.model_name.route_key}_path"))
      assert_response(:success)
      assert_select("tr##{obj.class.model_name.singular}_#{obj.id} a.action_link_#{action}", tf)
    end

end