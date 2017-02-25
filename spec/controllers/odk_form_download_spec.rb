require "spec_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe FormsController, type: :request do
  let!(:mission) { create(:mission) }
  let!(:user) { create(:user, role_name: :coordinator, mission: mission) }
  let(:form) { create(:form, mission: mission, question_types: %w(integer integer)) } # No select1's
  let(:form_select) { create(:form, mission: mission, question_types: %w(integer select_one)) } # Regular select1
  let(:form_multiselect) do
    create(:form, mission: mission, question_types: %w(integer multilevel_select_one)) # Multilevel select1
  end


  before do
    login(user)
    form.publish!
    form_select.publish!
    form_multiselect.publish!
  end

  context "for regular mission" do
    describe "listing forms" do
      it "should succeed" do
        get_s( "/en/m/#{mission.compact_name}/formList", format: :xml)

        # Only form3 should have a manifest.
        assert_select("xform", count: 3) do |elements|
          elements.each_with_index do |e,i|
            assert_select(e, "manifestUrl", count: i == 2 ? 1 : 0)
          end
        end
      end

      it "should succeed with no locale" do
        get_s("/m/#{mission.compact_name}/formList", format: :xml)
      end
    end

    describe "showing forms" do
      it "should succeed" do
        # XML rendering details are tested elsewhere.
        get_s("/en/m/#{mission.compact_name}/forms/#{form_multiselect.id}", format: :xml)
      end

      it "should succeed with no locale" do
        get_s("/m/#{mission.compact_name}/forms/#{form_multiselect.id}", format: :xml)
      end
    end

    describe "odk manifest" do
      context "for form with no option sets" do
        it "should render empty manifest tag" do
          get_s("/en/m/#{mission.compact_name}/forms/#{form.id}/manifest")
          assert_select("manifest", count: 1)
          assert_select("mediaFile", count: 0)
        end
      end

      context "for normal form" do
        it "should render regular manifest tag" do
          get_s("/m/#{mission.compact_name}/forms/#{form_multiselect.id}/manifest")
          @ifa = ItemsetsFormAttachment.new(form: form_multiselect)
          assert_select("filename", text: "itemsets.csv")
          assert_select("hash", text: @ifa.md5)
          assert_select("downloadUrl", text: "http://www.example.com/#{@ifa.path}")
        end
      end
    end

    describe "getting itemsets file" do
      context "for form with option sets" do
        before do
          @ifa = ItemsetsFormAttachment.new(form: form_multiselect)
          @ifa.ensure_generated
        end

        it "should succeed" do
          get_s("/#{@ifa.path}")
          expect(response).to be_success
          expect(response.body).to match(/,Cat/)
        end
      end
    end
  end

  context "for locked mission" do
    let!(:mission) { create(:mission, locked: true) }

    it "listing forms should return 403" do
      get("/en/m/#{mission.compact_name}/formList", format: :xml)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end

    it "showing form with format xml should return 403" do
      get("/m/#{mission.compact_name}/forms/#{form.id}", format: :xml)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end
  end
end
