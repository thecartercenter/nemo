# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe FormsController, :odk, type: :request do
  include_context "basic auth"

  let(:mission) { create(:mission) }
  let(:user) { create(:user, role_name: :coordinator, mission: mission) }
  let(:form_simple) { create(:form, :live, mission: mission) }
  let(:form_select) { create(:form, :live, mission: mission, question_types: %w[integer select_one]) }
  let(:form_small_multi) do
    create(:form, :live, mission: mission, question_types: %w[integer multilevel_select_one])
  end
  let(:form_both_multi) do
    create(:form, :live, mission: mission,
                         question_types: %w[integer multilevel_select_one super_multilevel_select_one])
  end

  before do
    # Stub threshold constant so that multilevel opt set is rendered normally,
    # but super_multilevel opt set is rendered as external.
    stub_const(ODK::OptionSetDecorator, "EXTERNAL_CSV_METHOD_THRESHOLD", 7)
  end

  context "for regular mission" do
    describe "listing forms" do
      let!(:forms) { [form_simple, form_select, form_small_multi, form_both_multi] }

      it "should succeed" do
        get("/en/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: auth_header)
        expect(response).to be_successful

        # Only form_both_multi should have a manifest.
        assert_select("xform", count: 4) do |elements|
          elements.each do |element|
            form_id = element.to_s.match(%r{:(.+)</formID>})[1]
            assert_select(element, "manifestUrl", form_both_multi.id == form_id ? 1 : 0)
            assert_select(element, "majorMinorVersion",
              count: 1, text: forms.detect { |f| f.id == form_id }.number)
          end
        end
      end

      it "should succeed with no locale" do
        get("/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: auth_header)
        expect(response).to be_successful
      end
    end

    describe "showing forms" do
      it "should succeed" do
        # XML rendering details are tested elsewhere.
        get(
          "/en/m/#{mission.compact_name}/forms/#{form_both_multi.id}",
          params: {format: :xml},
          headers: auth_header
        )
        expect(response).to be_successful
      end

      it "should succeed with no locale" do
        get(
          "/m/#{mission.compact_name}/forms/#{form_both_multi.id}",
          params: {format: :xml},
          headers: auth_header
        )
        expect(response).to be_successful
      end
    end

    describe "odk manifest" do
      context "for form with only small option sets" do
        it "should render empty manifest tag" do
          get("/en/m/#{mission.compact_name}/forms/#{form_small_multi.id}/manifest", headers: auth_header)
          expect(response).to be_successful
          assert_select("manifest", count: 1)
          assert_select("mediaFile", count: 0)
        end
      end

      context "for form with small and large multilevel option sets" do
        let(:ifa) { ODK::ItemsetsFormAttachment.new(form: form_both_multi) }

        it "should render regular manifest tag" do
          get("/m/#{mission.compact_name}/forms/#{form_both_multi.id}/manifest", headers: auth_header)
          expect(response).to be_successful
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
            get("/m/#{mission.compact_name}/forms/#{form_both_multi.id}/manifest", headers: auth_header)
            expect(response).to be_successful
            assert_select("downloadUrl", text: "https://www.example.com/#{ifa.path}")
          end
        end
      end

      context "for forms with media prompts" do
        let(:form) { create(:form, :live, mission: mission, question_types: %w[text integer]) }

        before do
          form.c[0].question.media_prompt.attach(io: audio_fixture("powerup.mp3"), filename: "powerup.mp3")
          form.c[1].question.media_prompt.attach(io: audio_fixture("powerup.wav"), filename: "powerup.wav")
        end

        it "should render manifest tags correctly" do
          get("/m/#{mission.compact_name}/forms/#{form.id}/manifest", headers: auth_header)
          expect(response).to be_successful

          download_url = "http://www.example.com/en/m/#{mission.compact_name}/questions"

          assert_select("mediaFile", count: 2) do |elements|
            assert_select(elements[0], "filename", text: "#{form.c[0].question.id}_media_prompt.mp3")
            assert_select(elements[0], "hash", text: "5/46pAa4tnIJudicDNUKqA==")
            assert_select(
              elements[0],
              "downloadUrl",
              text: "#{download_url}/#{form.c[0].question.id}/media_prompt"
            )

            assert_select(elements[1], "filename", text: "#{form.c[1].question.id}_media_prompt.wav")
            assert_select(elements[1], "hash", text: "/y/R4glGXFv/p4S1xX2ExA==")
            assert_select(
              elements[1],
              "downloadUrl",
              text: "#{download_url}/#{form.c[1].question.id}/media_prompt"
            )
          end
        end

        describe "should download successfully" do
          let(:url_prefix) { "/en/m/#{mission.compact_name}/questions" }

          it do
            get("#{url_prefix}/#{form.c[0].question_id}/media_prompt", headers: auth_header)
            expect(response).to be_successful
            expect(response.header["Content-Disposition"]).to include(form.c[0].question.id)
          end

          it do
            get("#{url_prefix}/#{form.c[1].question_id}/media_prompt", headers: auth_header)
            expect(response).to be_successful
            expect(response.header["Content-Disposition"]).to include(form.c[1].question.id)
          end

          it "should work with legacy endpoint" do
            get("#{url_prefix}/#{form.c[1].question_id}/audio_prompt", headers: auth_header)
            expect(response).to be_successful
          end
        end
      end
    end

    describe "getting itemsets file" do
      context "for form with option sets" do
        let(:ifa) { ODK::ItemsetsFormAttachment.new(form: form_both_multi) }

        before do
          ifa.ensure_generated
        end

        it "should succeed" do
          get("/#{ifa.path}", headers: auth_header)
          expect(response).to be_successful
          expect(response.body).to match(/,Cat/) # Full contents tested in model spec
        end
      end
    end
  end

  context "for locked mission" do
    let(:mission) { create(:mission, locked: true) }

    it "listing forms should return 403" do
      get("/en/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: auth_header)
      expect(response.status).to eq(403)
      expect(response.body.strip).to be_empty
    end

    it "showing form with format xml should return 403" do
      get("/m/#{mission.compact_name}/forms/#{form_simple.id}", params: {format: :xml}, headers: auth_header)
      expect(response.status).to eq(403)
      expect(response.body.strip).to be_empty
    end
  end
end
