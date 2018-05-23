require "spec_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "responses", type: :request do
  let!(:form) { create(:form, :published, question_types: %w(integer multilevel_select_one)) }
  let!(:option_set) { OptionSet.first }
  let!(:plants) { option_set.root_node.children.detect { |c| c.option_name == "Plant" } }
  let!(:plant) { plants.option }
  let!(:tulip) { plants.children.detect { |c| c.option_name == "Tulip" }.option }
  let!(:oak) { plants.children.detect { |c| c.option_name == "Oak" }.option }
  let!(:user) { get_user }
  let(:integer_qing) { form.questionings.detect { |qing| qing.qtype_name == "integer" } }
  let(:select_qing) {  form.questionings.detect { |qing| qing.qtype_name == "select_one" } }
  let(:response_attrs) do
    {
      user_id: user.id,
      form_id: form.id,
      answers_attributes: {
        "0" => {
          questioning_id: integer_qing.id,
          relevant: "1",
          value: "42",
        },
        "1" => {
          questioning_id: select_qing.id,
          relevant: "1",
          option_id: plant.id,
          rank: 1
        },
        "2" => {
          questioning_id: select_qing.id,
          relevant: "1",
          option_id: oak.id,
          rank: 2
        }
      }
    }
  end

  before do
    login(user)
  end

  describe "create" do
    it "should work" do
      post(responses_path(mode: "m", mission_name: get_mission.compact_name), response: response_attrs )
      @obj = Response.first
      expect(response).to redirect_to responses_path
      expect(@obj.user).to eq user
      expect(@obj.form).to eq form
      expect(@obj.answers.size).to eq 3
    end
  end

  describe "update" do
    let(:obj) { Response.create(response_attrs.merge(mission: get_mission)) }

    it "should work" do
      put(url_for(obj), response: response_attrs.merge(
        answers_attributes: {
          "2" => {
            id: obj.answers[2].id,
            relevant: "1",
            option_id: tulip.id,
            rank: 2
          }
        }
      ))
      expect(response).to redirect_to responses_path(mission_name: get_mission.compact_name)
      expect(Response.count).to eq 1
      @obj = Response.first
      expect(@obj.answers.size).to eq 3
      expect(@obj.answers.last.option.name).to eq "Tulip"
    end
  end

  describe "csv", :csv do
    before do
      create(:response, form: form, answer_values: %w(2 Animal))
      create(:response, form: form, answer_values: %w(15 Plant))
    end

    it "should produce valid CSV" do
      get_s(responses_path(mode: "m", mission_name: get_mission.compact_name, format: :csv))
      expect(response.headers["Content-Disposition"]).to match(
        /attachment; filename="elmo-#{get_mission.compact_name}-responses-\d{4}-\d\d-\d\d-\d{4}.csv"/)
      result = CSV.parse(response.body)
      expect(result.size).to eq 3 # 2 response rows, 1 header row
      expect(result[1][10]).to eq "Animal"
      expect(result[2][10]).to eq "Plant"
    end

    context "with numeric option value" do
      before { option_set.options.first.update!(value: 123) }

      it "should include option value instead of name" do
        get_s(responses_path(mode: "m", mission_name: get_mission.compact_name, format: :csv))
        result = CSV.parse(response.body)
        expect(result[1][10]).to eq "123"
        expect(result[2][10]).to eq "Plant"
      end
    end
  end
end
