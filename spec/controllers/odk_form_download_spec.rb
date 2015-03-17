require 'spec_helper'

# Using request spec b/c Authlogic won't work with controller spec
describe FormsController, type: :request do
  before do
    @mission = create(:mission)
    @user = create(:user, role_name: :observer, mission: @mission)
    login(@user)
  end

  context 'for regular mission' do
    before do
      @form1 = create(:form, mission: @mission, question_types: %w(integer integer)) # No select1's
      @form2 = create(:form, mission: @mission, question_types: %w(integer select_one)) # Regular select1
      @form3 = create(:form, mission: @mission, question_types: %w(integer multi_level_select_one)) # Multilevel select1
      @form1.publish!
      @form2.publish!
      @form3.publish!
    end

    describe 'listing forms' do
      it 'should succeed' do
        get_s(odk_form_list_path)

        # Only form3 should have a manifest.
        assert_select('xform', count: 3) do |elements|
          elements.each_with_index do |e,i|
            assert_select(e, 'manifestUrl', count: i == 2 ? 1 : 0)
          end
        end
      end
    end

    describe 'showing forms' do
      it 'should succeed' do
        # XML rendering details are tested elsewhere.
        get_s(odk_form_path(@form3))
      end
    end

    describe 'odk manifest' do
      context 'for form with no option sets' do
        it 'should render empty manifest tag' do
          get_s(odk_form_manifest_path(@form1))
          assert_select('manifest', count: 1)
          assert_select('mediaFile', count: 0)
        end
      end

      context 'for normal form' do
        it 'should render regular manifest tag' do
          get_s(odk_form_manifest_path(@form3))
          @ifa = ItemsetsFormAttachment.new(form: @form3)
          assert_select('filename', text: 'itemsets.csv')
          assert_select('hash', text: @ifa.md5)
          assert_select('downloadUrl', text: "http://www.example.com/#{@ifa.path}")
        end
      end
    end

    describe 'getting itemsets file' do
      context 'for form with option sets' do
        before do
          @ifa = ItemsetsFormAttachment.new(form: @form3)
          @ifa.ensure_generated
        end

        it 'should succeed' do
          get_s(@ifa.path)
          expect(response).to be_success
          expect(response.body).to match(/,Cat/)
        end
      end
    end
  end

  context 'for locked mission' do
    before do
      @mission.update_attributes!(locked: true)
      @form1 = create(:form, mission: @mission, question_types: %w(integer integer))
      @form1.publish!
    end

    it 'listing forms should return 403' do
      get(odk_form_list_path)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end

    it 'showing form with format xml should return 403' do
      get(odk_form_path(@form1))
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end
  end
end
