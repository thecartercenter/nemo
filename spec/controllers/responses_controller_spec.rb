require 'spec_helper'

# Using request spec b/c Authlogic won't work with controller spec
describe ResponsesController, type: :request do
  before do
    @form = create(:form, question_types: %w(integer select_one), use_multilevel_option_set: true)
    @option_set = OptionSet.first
    @plant = @option_set.root_node.c[1].option
    @tulip = @option_set.root_node.c[1].c[0].option
    @oak = @option_set.root_node.c[1].c[1].option
    @user = get_user
    login(@user)
  end

  describe 'create' do
    before do
      post(responses_path(mode: 'm', mission_name: get_mission.compact_name), response: {
        user_id: @user.id,
        form_id: @form.id,
        answers_attributes: {
          '0' => {
            questioning_id: @form.questionings[0].id,
            relevant: '1',
            value: '42',
          },
          '1_0' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: @plant.id,
            rank: 1
          },
          '1_1' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: @oak.id,
            rank: 2
          }
        }
      })
    end

    it 'should work' do
      @obj = Response.first
      expect(response).to redirect_to responses_path
      expect(@obj.user).to eq @user
      expect(@obj.form).to eq @form
      expect(@obj.answers.size).to eq 3
    end
  end

  describe 'update' do
    before do
      @obj = Response.create(
        mission: get_mission,
        user_id: @user.id,
        form_id: @form.id,
        answers_attributes: {
          '0' => {
            questioning_id: @form.questionings[0].id,
            relevant: '1',
            value: '42',
          },
          '1_0' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: @plant.id,
            rank: 1
          },
          '1_1' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: @oak.id,
            rank: 2
          }
        }
      )
    end

    it 'should work' do
      put(url_for(@obj), response: {
        user_id: @user.id,
        form_id: @form.id,
        answers_attributes: {
          '0' => {
            id: @obj.answers[0].id,
            relevant: '1',
            value: '45',
          },
          '1_0' => {
            id: @obj.answers[1].id,
            relevant: '1',
            option_id: @plant.id,
            rank: 1
          },
          '1_1' => {
            id: @obj.answers[2].id,
            relevant: '1',
            option_id: @tulip.id,
            rank: 2
          }
        }
      })
      expect(response).to redirect_to responses_path(mission_name: get_mission.compact_name)
      expect(Response.count).to eq 1
      @obj = Response.first
      expect(@obj.answers.size).to eq 3
      expect(@obj.answers[2].option.name).to eq 'Tulip'
    end
  end

  describe 'csv' do
    before do
      create(:response, :form => @form, :answer_values => %w(2 Animal))
      create(:response, :form => @form, :answer_values => %w(15 Plant))
    end

    it 'should produce valid CSV' do
      get_s(responses_path(mode: 'm', mission_name: get_mission.compact_name, format: :csv))
      expect(response.headers['Content-Disposition']).to match(
        /attachment; filename="elmo-#{get_mission.compact_name}-responses-\d{4}-\d\d-\d\d-\d{4}.csv"/)
      result = CSV.parse(response.body)
      expect(result.size).to eq 5 # 4 answer rows, 1 header row
      expect(result[0].size).to eq 15
    end
  end
end
