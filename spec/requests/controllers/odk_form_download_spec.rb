require 'spec_helper'

describe FormsController do
  context 'for regular mission' do
    before do
      @mission = create(:mission)
      create_form_and_login_observer(@mission)
    end

    it 'listing forms should succeed' do
      get_s(odk_form_list_path)
    end

    it 'showing form with format xml should succeed' do
      # XML rendering details are tested elsewhere.
      get_s(odk_form_path(@form))
    end

    it 'getting form manifest should succeed' do
      get_s(odk_form_manifest_path(@form))
    end
  end

  context 'for locked mission' do
    before do
      @mission = create(:mission, locked: true)
      create_form_and_login_observer(@mission)
    end

    it 'listing forms should return 403' do
      get(odk_form_list_path)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end

    it 'showing form with format xml should return 403' do
      get(odk_form_path(@form))
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end
  end

  def create_form_and_login_observer(mission)
    @form = create(:form, mission: mission)
    @form.publish!
    @user = create(:user, role_name: :observer, mission: mission)
    login(@user)
  end
end
