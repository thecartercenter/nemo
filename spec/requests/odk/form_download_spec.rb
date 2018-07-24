# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe FormsController, :odk, type: :request do
  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: :coordinator, mission: mission) }
  let(:form_simple) { create(:form, :published, mission: mission) }
  let(:form_select) { create(:form, :published, mission: mission, question_types: %w[integer select_one]) }
  let(:form_multiselect) do
    create(:form, :published, mission: mission, question_types: %w[integer multilevel_select_one])
  end
  let(:basic_auth) { {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)} }

  context "for regular mission" do
    describe "listing forms" do
      let!(:forms) { [form_simple, form_select, form_multiselect] }

      it "should succeed" do
        get("/en/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: basic_auth)
        expect(response).to be_success

        # Only form_multiselect should have a manifest.
        assert_select("xform", count: 3) do |elements|
          elements.each do |element|
            should_have_manifest = element.to_s.include?(":#{form_multiselect.id}</formID>")
            assert_select(element, "manifestUrl", should_have_manifest ? 1 : 0)
          end
        end
      end

      it "should succeed with no locale" do
        get("/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: basic_auth)
        expect(response).to be_success
      end
    end

    describe "showing forms" do
      it "should succeed" do
        # XML rendering details are tested elsewhere.
        get(
          "/en/m/#{mission.compact_name}/forms/#{form_multiselect.id}",
          params: {format: :xml},
          headers: basic_auth
        )
        expect(response).to be_success
      end

      it "should succeed with no locale" do
        get(
          "/m/#{mission.compact_name}/forms/#{form_multiselect.id}",
          params: {format: :xml},
          headers: basic_auth
        )
        expect(response).to be_success
      end
    end

    describe "odk manifest" do
      context "for form with no option sets" do
        it "should render empty manifest tag" do
          get("/en/m/#{mission.compact_name}/forms/#{form_simple.id}/manifest", headers: basic_auth)
          expect(response).to be_success
          assert_select("manifest", count: 1)
          assert_select("mediaFile", count: 0)
        end
      end

      context "for normal form" do
        let(:ifa) { ItemsetsFormAttachment.new(form: form_multiselect) }

        it "should render regular manifest tag" do
          get("/m/#{mission.compact_name}/forms/#{form_multiselect.id}/manifest", headers: basic_auth)
          expect(response).to be_success
          assert_select("filename", text: "itemsets.csv")
          assert_select("hash", text: ifa.md5)
          assert_select("downloadUrl", text: "http://www.example.com/#{ifa.path}")
        end

        context "on https" do
          around do |example|
            configatron.url.protocol = "https"
            example.run
            configatron.url.protocol = "http"
          end

          it "should use https in URL" do
            get("/m/#{mission.compact_name}/forms/#{form_multiselect.id}/manifest", headers: basic_auth)
            expect(response).to be_success
            assert_select("downloadUrl", text: "https://www.example.com/#{ifa.path}")
          end
        end
      end

      context "for forms with audio prompts" do
        let(:form) { create(:form, :published, mission: mission, question_types: %w[text integer]) }

        before do
          form.c[0].question.update!(audio_prompt: audio_fixture("powerup.mp3"))
          form.c[1].question.update!(audio_prompt: audio_fixture("powerup.wav"))
        end

        it "should render manifest tags correctly" do
          get("/m/#{mission.compact_name}/forms/#{form.id}/manifest", headers: basic_auth)
          expect(response).to be_success

          download_url = "http://www.example.com/en/m/#{mission.compact_name}/questions"

          assert_select("mediaFile", count: 2) do |elements|
            assert_select(elements[0], "filename", text: "#{form.c[0].question.id}_audio_prompt.mp3")
            assert_select(elements[0], "hash", text: "e7fe3aa406b8b67209b9d89c0cd50aa8")
            assert_select(
              elements[0],
              "downloadUrl",
              text: "#{download_url}/#{form.c[0].question.id}/audio_prompt"
            )

            assert_select(elements[1], "filename", text: "#{form.c[1].question.id}_audio_prompt.wav")
            assert_select(elements[1], "hash", text: "ff2fd1e209465c5bffa784b5c57d84c4")
            assert_select(
              elements[1],
              "downloadUrl",
              text: "#{download_url}/#{form.c[1].question.id}/audio_prompt"
            )
          end
        end

        describe "should download successfully" do
          let(:url_prefix) { "/en/m/#{mission.compact_name}/questions" }

          it do
            get("#{url_prefix}/#{form.c[0].question_id}/audio_prompt", headers: basic_auth)
            expect(response).to be_success
            expect(response.header["Content-Disposition"]).to include(form.c[0].question.id)
          end

          it do
            get("#{url_prefix}/#{form.c[1].question_id}/audio_prompt", headers: basic_auth)
            expect(response).to be_success
            expect(response.header["Content-Disposition"]).to include(form.c[1].question.id)
          end
        end
      end
    end

    describe "getting itemsets file" do
      context "for form with option sets" do
        let(:ifa) { ItemsetsFormAttachment.new(form: form_multiselect) }

        before do
          ifa.ensure_generated
        end

        it "should succeed" do
          get("/#{ifa.path}", headers: basic_auth)
          expect(response).to be_success
          expect(response.body).to match(/,Cat/)
        end
      end
    end
  end

  context "for locked mission" do
    let(:mission) { create(:mission, locked: true) }

    it "listing forms should return 403" do
      get("/en/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: basic_auth)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end

    it "showing form with format xml should return 403" do
      get("/m/#{mission.compact_name}/forms/#{form_simple.id}", params: {format: :xml}, headers: basic_auth)
      expect(response.status).to eq 403
      expect(response.body.strip).to be_empty
    end
  end
end
