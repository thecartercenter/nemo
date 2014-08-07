require 'spec_helper'

describe ResponsesController do
  before do
    @form = create(:form, :question_types => %w(integer select_one))
    @user = get_user
    login(@user)
  end

  describe 'create' do
    it 'should work' do
      post(responses_path(mode: 'm', mission_name: get_mission.compact_name), response: {
        user_id: @user.id,
        form_id: @form.id,
        answer_sets: {
          '0' => {
            questioning_id: @form.questionings[0].id,
            relevant: '1',
            value: '42',
          },
          '1' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: Option.first.id,
          }
        }
      })
      obj = Response.first
      expect(response).to redirect_to responses_path
      expect(obj.user).to eq @user
      expect(obj.form).to eq @form
      expect(obj.answers.size).to eq 2
    end
  end

  describe 'update' do
    before do
      @obj = create(:response, :form => @form, :_answers => %w(42 Cat))
    end

    it 'should work' do
      put(url_for(@obj), response: {
        user_id: @user.id,
        form_id: @form.id,
        answer_sets: {
          '0' => {
            questioning_id: @form.questionings[0].id,
            relevant: '1',
            value: '45',
          },
          '1' => {
            questioning_id: @form.questionings[1].id,
            relevant: '1',
            option_id: Option.last.id,
          }
        }
      })
      expect(Response.count).to eq 1
      obj = Response.first
      expect(response).to redirect_to responses_path
      expect(obj.answers.size).to eq 2
    end
  end


  describe 'csv' do
    before do
      create(:response, :form => @form, :_answers => %w(2 Cat))
      create(:response, :form => @form, :_answers => %w(15 Dog))
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
