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
      let!(:unrendered_form) { create(:form, :live, mission: mission) }
      let!(:forms) { [form_simple, form_select, form_small_multi, form_both_multi] }

      before do
        forms.each { |f| ODK::FormRenderJob.perform_now(f) }
      end

      it "should succeed, skipping live but not yet rendered forms" do
        get("/en/m/#{mission.compact_name}/formList", params: {format: :xml}, headers: auth_header)
        expect(response).to be_successful

        # Only form_both_multi should have a manifest.
        assert_select("xform", count: 4) do |elements|
          elements.each do |element|
            form_id = element.to_s.match(%r{:(.+)</formID>})[1]
            assert_select(element, "manifestUrl", form_both_multi.id == form_id ? 1 : 0)
            assert_select(element, "hash", text: /\Amd5:[a-f0-9]{32}\z/)
            assert_select(element, "version",
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
      before do
        ODK::FormRenderJob.perform_now(form_both_multi)
      end

      it "should succeed" do
        # XML rendering details are tested elsewhere.
        get(
          "/en/m/#{mission.compact_name}/forms/#{form_both_multi.id}",
          params: {format: :xml},
          headers: auth_header
        )
        expect(response).to be_successful
        expect(response.body).to include("<h:title>")
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
        let(:itemsets_attachment) { ODK::ItemsetsFormAttachment.new(form: form_both_multi) }

        it "should render regular manifest tag" do
          get("/m/#{mission.compact_name}/forms/#{form_both_multi.id}/manifest", headers: auth_header)
          expect(response).to be_successful
          assert_select("filename", text: "itemsets.csv")
          assert_select("hash", text: "md5:#{itemsets_attachment.md5}")
          assert_select("downloadUrl", text: "http://www.example.com/#{itemsets_attachment.path}")
        end

        context "on https" do
          around do |example|
            with_env("NEMO_URL_PROTOCOL" => "https", "NEMO_URL_PORT" => "443") do
              example.run
            end
          end

          it "should use https in URL" do
            get("/m/#{mission.compact_name}/forms/#{form_both_multi.id}/manifest", headers: auth_header)
            expect(response).to be_successful
            assert_select("downloadUrl", text: "https://www.example.com/#{itemsets_attachment.path}")
          end
        end
      end

      context "for forms with media prompts" do
        let(:form) { create(:form, :live, mission: mission, question_types: %w[text integer]) }

        before do
          form.c[0].question.media_prompt.attach(io: audio_fixture("powerup.mp3"), filename: "one.mp3")
          form.c[1].question.media_prompt.attach(io: audio_fixture("powerup.mp3"), filename: "two.mp3")
        end

        it "should render manifest tags correctly" do
          get("/m/#{mission.compact_name}/forms/#{form.id}/manifest", headers: auth_header)
          expect(response).to be_successful

          assert_select("mediaFile", count: 2) do |elements|
            assert_select(elements[0], "filename", text: "#{form.c[0].question.id}_media_prompt.mp3")
            assert_select(elements[0], "hash", text: "md5:5/46pAa4tnIJudicDNUKqA==")
            assert_select(
              elements[0],
              "downloadUrl",
              text: download_url(form.c[0].media_prompt)
            )

            assert_select(elements[1], "filename", text: "#{form.c[1].question.id}_media_prompt.mp3")
            assert_select(elements[1], "hash", text: "md5:5/46pAa4tnIJudicDNUKqA==")
            assert_select(
              elements[1],
              "downloadUrl",
              text: download_url(form.c[1].media_prompt)
            )
          end
        end

        it "should download successfully" do
          get(download_url(form.c[0].media_prompt), headers: auth_header)
          follow_redirect!
          expect(response).to be_successful
          expect(response.header["Content-Disposition"]).to include(form.c[0].question.id)
        end
      end
    end

    describe "getting itemsets file" do
      context "for form with option sets" do
        let(:itemsets_attachment) { ODK::ItemsetsFormAttachment.new(form: form_both_multi) }

        before do
          itemsets_attachment.ensure_generated
        end

        it "should succeed" do
          get("/#{itemsets_attachment.path}", headers: auth_header)
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

def download_url(attachment)
  rails_blob_url(attachment, disposition: "attachment")
end
