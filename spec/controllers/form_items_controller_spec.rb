require 'spec_helper'

describe FormItemsController, type: :request do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: ['text', ['text', 'text']])
    @qing = @form.c[0]
    @qing_group = @form.c[1]
    login(@user)
  end

  describe 'update' do
    context 'when valid ancestry' do
      before(:each) do
        put(form_item_path(@qing, mode: 'm', mission_name: get_mission.compact_name),
           'rank' => 3, 'parent_id' => @qing_group.id )
      end

      it 'should be successful' do
        expect(response).to be_success
      end

      it 'should update rank and ancestry' do
        params = controller.params
        expect(params[:rank]).to eq "3"
        expect(params[:parent_id]).to eq @qing_group.id.to_s
      end
    end

    context 'when invalid ancestry' do
      before(:each) do
        @qing.ancestry = @qing_group.id
        @qing.save

        put(form_item_path(@qing_group, mode: 'm', mission_name: get_mission.compact_name),
           'rank' => 3, 'parent_id' => @qing.id)
      end

      it 'should not be successful' do
        expect(response.status).to eq(422)
      end
    end
  end
end
