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

  private
    def assert_action_link(obj, action, tf)
      get(send("#{obj.class.model_name.route_key}_path"))
      assert_response(:success)
      assert_select("tr##{obj.class.model_name.singular}_#{obj.id} a.action_link_#{action}", tf)
    end

end