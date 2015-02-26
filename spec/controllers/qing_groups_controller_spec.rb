require 'spec_helper'

describe QingGroupsController, type: :request do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: %w(text text))
    @qing_group = create(:qing_group,
      form: @form, mission: get_mission, ancestry: @form.root_id)

    login(@user)
  end

  describe 'new' do
    it 'should be successful' do
      get(new_qing_group_path(@form))
      expect(response).to be_success
    end

    it 'should assign new qing_group' do
      get(new_qing_group_path(@form))
      expect(assigns(:qing_group)).to be_kind_of(QingGroup)
    end
  end

  describe 'create' do
    before(:each) do
      post(qing_groups_path(mission_name: get_mission.compact_name),
        'qing_group' => { 'form_id' => @form.id })
    end

    it 'should be successful' do
      expect(response).to be_success
    end

    it 'should render item partial' do
      expect(response).to render_template(:partial => 'qing_groups/_item')
    end

    it 'should create new qing_group' do
      qing_group = assigns(:qing_group)
      expect(qing_group).to be_kind_of(QingGroup)
      expect(qing_group.form_id).to eq @form.id
      expect(qing_group.ancestry).to eq @form.root_id
      expect(qing_group.mission).to eq get_mission
     end
  end

  describe 'update' do
    before(:each) do
      put(qing_group_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name),
        'qing_group' => { 'group_name_translations' => {'en' => 'New Group Name'} })
    end

    it 'should be successful' do
      expect(response).to be_success
    end

    it 'should change qing_group name' do
      expect(@qing_group.reload.group_name_en).to eq('New Group Name')
    end
  end

  describe 'show' do
    it 'should be successful' do
      get(qing_group_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name))
      expect(response).to be_success
    end
  end

  describe 'edit' do
    it 'should be successful' do
      get(edit_qing_group_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name))
      expect(response).to be_success
    end
  end

  describe 'destroy' do
    it 'should be successful' do
      delete(qing_group_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name))
      expect(response).to redirect_to edit_form_path(@form)
    end
  end


end
