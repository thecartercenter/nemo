require "spec_helper"

describe "form items" do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:form) { create(:form, question_types: ["text", ["text", "text"]]) }
  let(:qing) { form.children.select{ |c| c.type == "Questioning" }.first }
  let(:qing_group) { form.children.select { |c| c.type == "QingGroup" }.first }

  before do
    login(user)
  end

  describe "update" do
    context "when valid ancestry" do
      before(:each) do
        put(form_item_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "rank" => 3, "parent_id" => qing_group.id )
      end

      it "should be successful" do
        expect(response).to be_success
      end

      it "should update rank and ancestry" do
        params = controller.params
        expect(params[:rank]).to eq "3"
        expect(params[:parent_id]).to eq qing_group.id.to_s
      end
    end
  end
end
