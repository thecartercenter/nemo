require 'rails_helper'

describe 'DataIntegrity' do
  include PathHelper

  before do
    admin = create(:user, admin: true)
    login(admin)
  end

  it "unpublished form should be deletable" do
    form = create(:form)
    assert_action_link(form, :destroy, true)
    assert_deletable(form)
  end

  it "published form should not be deletable" do
    form = create(:form)

    # publish and make sure it's published
    form.publish!
    expect(form.reload.published?).to be true

    assert_action_link(form, :destroy, false)
  end

  it "form with responses should not be deletable" do
    form = create(:form)
    create(:response, form: form)

    assert_action_link(form, :destroy, false)
  end

  it "standard form copy should be deletable" do
    form = create(:form, is_standard: true)
    copy = form.replicate(mode: :to_mission, dest_mission: get_mission)
    assert_action_link(copy, :destroy, true)
    assert_deletable(copy)
  end

  it "published form should be renameable" do
    form = create(:form)
    form.publish!

    assert_field_changeable(form, :name)
  end

  it "should not be able to add non-required question to published form" do
    form = create(:form)
    form.publish!

    # check for no add question link
    get(form_path(form, mode: 'm', mission_name: get_mission.compact_name))
    expect(response).to be_success
    assert_select("a[href$=choose_questions]", false)
  end

  # DID NOT FINISH WRITING ALL THESE TESTS DUE TO TIME CONSTRAINTS

  private
    def assert_action_link(obj, action, tf)
      # Load the index view for the object
      get(dynamic_path(obj, action: :index, mode: 'm', mission_name: obj.mission.compact_name))
      expect(response).to be_success
      assert_select("tr##{obj.class.model_name.singular}_#{obj.id} a.action_link_#{action}", tf)
    end

    def assert_deletable(obj)
      # do delete
      delete(send("#{obj.class.model_name.singular}_path", obj, mode: 'm', mission_name: obj.mission.compact_name))

      assert_successful_action(obj)

      # ensure object was deleted
      expect(obj.class.exists?(obj.id)).to be false
    end

    def assert_field_changeable(obj, field)
      singular = obj.class.model_name.singular
      get(send("edit_#{singular}_path", obj, mode: 'm', mission_name: obj.mission.compact_name))
      expect(response).to be_success
      assert_select("input##{singular}_#{field}")
      new_val = "new val #{rand(100000000)}"
      put(send("#{singular}_path", obj), params: {singular => {field => new_val}})
      follow_redirect!
      expect(obj.reload.send(field)).to eq(new_val)
    end

    def assert_successful_action(obj)
      # ensure no errors
      follow_redirect!
      expect(response).to be_success
      expect(obj.errors.empty?).to be true
      expect(flash[:error]).to be_nil
      expect(assigns(:error_msg)).to be_nil
    end
end
