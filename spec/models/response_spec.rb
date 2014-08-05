require 'spec_helper'

describe Response do
  describe 'all_answers=' do
    context 'on create' do
      before do
        @response = Response.new
      end

      it 'should build new answers' do
        @answers = []
        expect(@answers).to receive(:build).exactly(3).times
        allow(@response).to receive(:answers).and_return(@answers)

        # We submit two answers with diff ranks for questioning 2
        @response.all_answers = {
          '0' => { questioning_id: 1, value: '42' },
          '1' => { questioning_id: 2, rank: 1, option_id: 12 },
          '2' => { questioning_id: 2, rank: 2, option_id: 14 }
        }
      end
    end

    context 'on update' do
      before do
        @response = Response.new
        @answers = [
          {questioning_id: 1, value: '42'},
          {questioning_id: 2, rank: 1, option_id: 12},
          {questioning_id: 2, rank: 2, option_id: 14}
        ]
        allow(@response).to receive(:answers).and_return(@answers)
      end

      it 'should replace all existing answers' do
        new_answers = { # Note shuffling - order shouldn't matter.
          '2' => {questioning_id: 2, rank: 2, option_id: 24},
          '0' => {questioning_id: 1, value: '43'},
          '1' => {questioning_id: 2, rank: 1, option_id: 22},
        }
        # Each answer should get updated, regardless of order.
        @answers.each_with_index{ |a, i| expect(a).to receive(:attributes=).with(new_answers[i.to_s]) }
        @response.all_answers = new_answers
      end
    end
  end
end
