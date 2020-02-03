# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "questionings", type: :request do
  let(:user) { create(:user, role_name: "coordinator") }

  before do
    login(user)
  end

  describe "update" do
    context "when published" do
      let(:form) { create(:form, :live, question_types: %w[text text]) }
      let(:qing) { form.questionings.first }

      it "changing name should succeed" do
        put(questioning_path(qing, mode: "m", mission_name: get_mission.compact_name),
          params: {
            "questioning" => {
              "question_attributes" => {
                "id" => qing.question_id,
                "name_en" => "Foo"
              }
            }
          })
        expect(response).to be_redirect
        expect(qing.reload.name_en).to eq("Foo")
      end
    end
  end
end
