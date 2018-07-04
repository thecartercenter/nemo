require 'rails_helper'

describe 'AdminMode' do

  before do
    @admin = create(:user, admin: true)
    @nonadmin = create(:user)
  end

  it "admin mode link works" do
    login(@admin)
    assert_select('a.admin-mode[href="/en/admin"]', true)
    get('/en/admin')
    expect(response).to be_success
  end

  it "controller admin_mode helper should work properly" do
    get(login_url)
    expect(@controller.send(:admin_mode?)).to eq(false)

    login(@admin)
    get(basic_root_url)
    expect(@controller.send(:admin_mode?)).to eq(false)

    get(admin_root_url(mode: 'admin'))
    expect(@controller.send(:admin_mode?)).to eq(true)
  end

  it "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(basic_root_url)
    assert_select("div#userinfo a.admin-mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.admin-mode", false)
  end

  it "params admin_mode should be correct" do
    login(@admin)
    get_s(basic_root_url)
    expect(response).to be_success
    expect(request.params[:mode]).to be_nil
    get_s('/en/admin')
    expect(request.params[:mode]).to eq('admin')
  end

  it "admin mode should not be permitted for non-admins" do
    login(@nonadmin)
    get('/en/admin')
    expect(response.status).to eq(302)
    expect(assigns(:access_denied)).not_to be_nil, "access should have been denied"
  end

  it "mission dropdown should not be visible in admin mode" do
    login(@admin)
    assert_select('select#change-mission')
    get_s('/en/admin')

    assert_select('select#change-mission', false)

    # exit admin mode link should be visible instead
    assert_select('a.exit-admin-mode')
  end

  it "creating a form in admin mode should create a standard form" do
    login(@admin)
    post(forms_path(mode: 'admin', mission_name: nil),
      params: {form: {name: 'Foo', smsable: false}})
    follow_redirect!
    f = assigns(:form)
    expect(f.mission).to be_nil
    expect(f.is_standard?).to be_truthy, 'new form should be standard'
  end

  it "creating a question in admin mode should create a standard question" do
    login(@admin)
    post(questions_path(mode: 'admin', mission_name: nil),
      params: {question: {code: 'Foo', qtype_name: 'integer', name_en: 'Stuff'}})
    follow_redirect!
    q = Question.order('created_at').last
    expect(q.mission).to be_nil
    expect(q.is_standard?).to be_truthy, 'new question should be standard'
  end

  it "valid delete of mission" do
    @mission = get_mission
    login(@admin)

    assert_difference('Mission.count', -1) do
      delete(mission_path(@mission.id, mode: 'admin'))
      follow_redirect!
    end
  end
end
