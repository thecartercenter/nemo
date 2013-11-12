require 'test_helper'

# this class contains tests for the general environment, e.g. admin mode
class AdminModeTest < ActionDispatch::IntegrationTest

  setup do
    @admin = FactoryGirl.create(:user, :admin => true)
    @nonadmin = FactoryGirl.create(:user)
  end

  test "path helpers still should work after addition of admin routes" do
    @option_set = FactoryGirl.create(:option_set)
    assert_equal("/en/option_sets/#{@option_set.id}", option_set_path(@option_set))
    assert_equal("/en", root_path)
    assert_equal("/en/admin", root_path(:admin_mode => 'admin'))
  end

  test "controller admin_mode helper should work properly" do
    get(root_url)
    assert(!@controller.send(:admin_mode?))
    login(@admin)
    get(root_url)
    assert(!@controller.send(:admin_mode?))
    get(root_url(:admin_mode => 'admin'))
    assert(@controller.send(:admin_mode?))
  end

  test "admin mode should only be available to admins" do
    # login as admin and check for admin mode link
    login(@admin)
    get(root_url)
    assert_select("div#userinfo a.goto_admin_mode")

    # login as other user and make sure not available
    logout
    login(@nonadmin)
    assert_select("div#userinfo a.goto_admin_mode", false)
  end

  test "params admin_mode should be correct" do
    login(@admin)
    get_success(root_url)
    assert_response(:success)
    assert_nil(request.params[:admin_mode])
    get_success('/admin')
    assert_not_nil(request.params[:admin_mode])
  end

  test "admin mode should not be permitted for non-admins" do
    login(@nonadmin)
    get('/admin')
    assert_access_denied
  end

  test "mission dropdown should not be visible in admin mode" do
    login(@admin)
    assert_select('select#user_current_mission_id')
    get('/admin')
    assert_select('select#user_current_mission_id', false)

    # exit admin mode link should be visible instead
    assert_select('a.exit_admin_mode')
  end

  test "users current mission and current_mission should be nil in admin mode" do
    login(@admin)
    assert_not_nil(@admin.current_mission)
    assert_not_nil(@controller.current_mission)

    get('/admin')
    @admin.reload
    assert_nil(@admin.current_mission)
    assert_nil(@controller.current_mission)
  end

  test "mission menu item should only appear in admin mode" do

  end

  test "creating a form in admin mode should create a standard form" do
    login(@admin)
    post_via_redirect(forms_path(:admin_mode => 'admin'), {:form => {:name => 'Foo', :smsable => false}})
    f = assigns(:form)
    assert_nil(f.mission)
    assert(f.is_standard?, 'new form should be standard')
  end

  test "creating a question in admin mode should create a standard question" do
    login(@admin)
    post_via_redirect(questions_path(:admin_mode => 'admin'), {:question => {:code => 'Foo', :qtype_name => 'integer', :name_en => 'Stuff'}})
    q = Question.order('created_at').last
    assert_nil(q.mission)
    assert(q.is_standard?, 'new question should be standard')
  end

  test "creating an option set in admin mode should create a standard option set and options" do
    login(@admin)
    post_via_redirect(option_sets_path(:admin_mode => 'admin'), {
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
    post_via_redirect(add_questions_form_path(f, :admin_mode => 'admin'), :selected => {q.id => '1'})
    f.reload
    assert_equal(q, f.questionings[0].question)
    assert(f.questionings[0].is_standard?)
  end

end
