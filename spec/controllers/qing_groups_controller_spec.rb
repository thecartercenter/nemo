require 'spec_helper'

describe QingGroupsController, type: :request do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: ['text', ['text', 'text']])
    @qing_group = @form.c[1]
    login(@user)
  end

  describe 'create' do
    before(:each) do
      post(qing_groups_path(mode: 'm', mission_name: get_mission.compact_name), qing_group: { form_id: @form.id })
    end

    it 'should be successful' do
      expect(response).to be_success
    end

    it 'should render item partial' do
      expect(response).to render_template(partial: 'qing_groups/_group')
    end

    it 'should create new qing_group' do
      qing_group = assigns(:qing_group)
      expect(qing_group).to be_kind_of(QingGroup)
      expect(qing_group.form_id).to eq @form.id
      expect(qing_group.ancestry).to eq @form.root_id.to_s
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

  describe 'destroy' do
    it 'should be successful' do
      group = create(:qing_group, form: @form, ancestry: @qing_group.id)
      delete(qing_group_path(group, mode: 'm', mission_name: get_mission.compact_name))
      expect(response).to be_success
    end

    it 'should return 404 for not empty groups' do
      delete(qing_group_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name))
      expect(response.status).to eq 404
    end
  end
end
