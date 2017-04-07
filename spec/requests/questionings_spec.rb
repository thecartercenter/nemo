require "spec_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "questionings", type: :request do
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  describe "update" do
    context "when published" do
      let(:form) { create(:form, :published, question_types: %w(text text)) }
      let(:qing) { form.questionings.first }

      it "changing name should succeed" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {
            "question_attributes" => {
              "id" => qing.question_id,
              "name_en" => "Foo"
            }
          }
        )
        expect(response).to be_redirect
        expect(qing.reload.name_en).to eq("Foo")
      end

      it "changing required flag should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => { "required" => "1" })
        expect(response).to redirect_to(unauthorized_path)
      end

      it "changing hidden flag should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => { "hidden" => "1" })
        expect(response).to redirect_to(unauthorized_path)
      end

      it "changing condition should be unauthorized" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "questioning" => {
            "condition_attributes" => {
              "ref_qing_id" => form.questionings[0].id,
              "op" => "eq",
              "value" => "foo"
            }
          }
        )
        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end
end
