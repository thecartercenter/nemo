# Tests for abilities related to Questioning object.
require 'spec_helper'

describe 'abilities for questionings' do
  context 'for coordinator role' do
    before do
      @user = create(:user, role_name: 'coordinator')
      @ability = Ability.new(user: @user, mode: 'mission', mission: get_mission)
    end

    it 'should be able to create but not index' do
      expect(@ability).to be_able_to(:create, Questioning)
      expect(@ability).not_to be_able_to(:index, Questioning) # There is no qing index
    end

    context 'when unpublished' do
      before do
        @form = create(:form, question_types: %w(text))
        @qing = @form.questionings[0]
      end

      it 'should be able to do all' do
        %w(show update update_required update_hidden update_condition destroy).each{ |op| expect(@ability).to be_able_to(op, @qing) }
      end

      context 'with answers' do
        before do
          create(:response, form: @form, answer_values: ['foo'])
        end

        it 'should be able to do all but destroy' do
          %w(show update update_required update_hidden update_condition).each{ |op| expect(@ability).to be_able_to(op, @qing) }
          %w(destroy).each{ |op| expect(@ability).not_to be_able_to(op, @qing) }
        end
      end
    end

    context 'when published' do
      before do
        @form = create(:form, question_types: %w(text))
        @form.publish!
        @qing = @form.questionings[0]
      end

      it 'should be able show and update only' do
        %w(show update).each{ |op| expect(@ability).to be_able_to(op, @qing) }
        %w(update_required update_hidden update_condition destroy).each{ |op| expect(@ability).not_to be_able_to(op, @qing) }
      end
    end

    context 'when unpublished std copy' do
      before do
        @std = create(:form, question_types: %w(text), is_standard: true)
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @qing = @copy.questionings[0]
      end

      it 'should be able to do all' do
        %w(show update update_hidden update_required update_condition destroy).each{ |op| expect(@ability).to be_able_to(op, @qing) }
      end
    end
  end
end
