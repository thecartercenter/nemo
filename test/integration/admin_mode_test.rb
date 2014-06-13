require 'test_helper'

# this class contains tests for the general environment, e.g. admin mode
class AdminModeTest < ActionDispatch::IntegrationTest

  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @nonadmin = FactoryGirl.create(:user)
  end

  test "admin mode link works" do
    login(@admin)
    assert_select('a.admin-mode[href=/en/admin]', true)
    get('/en/admin')
    assert_response(:success)
  end

  test "controller admin_mode helper should work properly" do
    get(login_url)
    assert_equal(false, @controller.send(:admin_mode?))

    login(@admin)
    get(basic_root_url)
    assert_equal(false, @controller.send(:admin_mode?))

    get(admin_root_url(:mode => 'admin'))
    assert_equal(true, @controller.send(:admin_mode?))
  end

  test "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(basic_root_url)
    assert_select("div#userinfo a.admin-mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.admin-mode", false)
  end

  test "params admin_mode should be correct" do
    login(@admin)
    get_success(basic_root_url)
    assert_response(:success)
    assert_nil(request.params[:mode])
    get_success('/en/admin')
    assert_equal('admin', request.params[:mode])
  end

  test "admin mode should not be permitted for non-admins" do
    login(@nonadmin)
    get('/en/admin')
    assert_access_denied
  end

  test "mission dropdown should not be visible in admin mode" do
    login(@admin)
    assert_select('form#change_mission')
    get_success('/en/admin')

    assert_select('form#change_mission', false)

    # exit admin mode link should be visible instead
    assert_select('a.exit-admin-mode')
  end

  test "creating a form in admin mode should create a standard form" do
    login(@admin)
    post_via_redirect(forms_path(:mode => 'admin'), {:form => {:name => 'Foo', :smsable => false}})
    f = assigns(:form)
    assert_nil(f.mission)
    assert(f.is_standard?, 'new form should be standard')
  end

  test "creating a question in admin mode should create a standard question" do
    login(@admin)
    post_via_redirect(questions_path(:mode => 'admin'), {:question => {:code => 'Foo', :qtype_name => 'integer', :name_en => 'Stuff'}})
    q = Question.order('created_at').last
    assert_nil(q.mission)
    assert(q.is_standard?, 'new question should be standard')
  end

  test "creating an option set in admin mode should create a standard option set and options" do
    login(@admin)
    post_via_redirect(option_sets_path(:mode => 'admin'), {
      :option_set => {:name => 'Foo',
        :optionings_attributes => {
          '0' => {
            :rank => 1,
            :option_attributes => {:name_en => 'Yes'}
          },
          '1' => {
            :rank => 2,
            :option_attributes => {:name_en => 'No'}
          }
        }
      }
    })
    os = OptionSet.order('created_at').last

    # make sure it got created correctly
    assert('Yes', os.options[0].name)

    # make sure mission is nil and is standard
    assert_nil(os.mission)
    assert(os.is_standard?, 'new option set should be standard')

    # make sure optionings and options are also ok
    assert_nil(os.optionings[0].mission)
    assert(os.optionings[0].is_standard?, 'new optioning should be standard')
    assert_nil(os.options[0].mission)
    assert(os.options[0].is_standard?, 'new option should be standard')
  end

  test "adding a question to form should create standard questioning" do
    login(@admin)
    f = FactoryGirl.create(:form, :is_standard => true)
    q = FactoryGirl.create(:question, :is_standard => true)
    post_via_redirect(add_questions_form_path(f, :mode => 'admin'), :selected => {q.id => '1'})
    f.reload
    assert_equal(q, f.questionings[0].question)
    assert(f.questionings[0].is_standard?)
  end

  test "valid delete of mission" do
    @mission = get_mission
    login(@admin)

    assert_difference('Mission.count', -1) do
      delete_via_redirect(mission_path(@mission.id, :mode => 'admin'))
    end
  end

  test "exit admin mode link leads back to last mission if exists" do
    login(@admin)

    # Visit a mission to establish the last mission.
    mission_url = "/en/m/#{get_mission.compact_name}"
    get(mission_url)

    get('/en/admin')
    assert_response(:success)
    assert_select("a.exit-admin-mode[href=#{mission_url}]")
  end

  test "exit admin mode link leads to basic mode if no last mission name stored" do
    login(@admin)
    get('/en/admin')
    assert_response(:success)
    assert_select("a.exit-admin-mode[href=/en]")
  end
end
