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
      @ifa = ItemsetsFormAttachment.new(form: @form)
      assert_select('filename', text: 'itemsets.csv')
      assert_select('hash', text: @ifa.md5)
      assert_select('downloadUrl', text: @ifa.path)
    end

    it 'getting itemsets file for form with option sets should succeed' do
      # We need an option set or the file won't exist.
      @os = create(:option_set)
      allow(@form).to receive(:option_sets).and_return([@os])
      @ifa = ItemsetsFormAttachment.new(form: @form)
      @ifa.ensure_generated
      get_s(@ifa.path)
      expect(response).to be_success
      expect(response.body).to match(/,Cat/)
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
