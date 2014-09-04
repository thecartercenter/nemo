require 'spec_helper'

describe FormsController do
  context 'for regular mission' do
    before do
      @mission = create(:mission)
      create_form_and_login_observer(@mission)
    end

    it 'listing forms should succeed' do
      get_s(forms_path(format: 'xml'))
    end

    it 'showing form with format xml should succeed' do
      # XML rendering details are tested elsewhere.
      get_s(form_path(@form, format: 'xml'))
    end
  end

  context 'for locked mission' do
    before do
      @mission = create(:mission, locked: true)
      create_form_and_login_observer(@mission)
    end

    it 'listing forms should return 403' do
      get(forms_path(format: 'xml'))
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end

    it 'showing form with format xml should return 403' do
      get(form_path(@form, format: 'xml'))
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
