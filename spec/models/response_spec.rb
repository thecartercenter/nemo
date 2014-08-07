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

  describe 'answer_sets' do
    before do
      @response = Response.new
      @q1, @q2 = double(), double()
      @sorted_answers = [ # These are in order because we're not testing ARs ordering capability.
        double(questioning: @q1, option_id: 10),
        double(questioning: @q2, rank: 1, option_id: 11),
        double(questioning: @q2, rank: 2, option_id: 12),
        double(questioning: @q2, rank: 3, option_id: 13)
      ]
      allow(@response).to receive(:sorted_answers).and_return(@sorted_answers)
      allow(@response).to receive(:visible_questionings).and_return([@q1, @q2])
    end

    context 'with no missing answers' do
      it 'should return answers grouped by questioning_id and sorted by rank' do
        expect(@response.answer_sets.map{|s| s.answers.map(&:option_id)}).to eq [[10], [11, 12, 13]]
      end
    end

    context 'with missing answer for multilevel question' do
      before do
        @sorted_answers.slice!(1,3)
      end

      it 'should build new answers' do
        expect(@q2).to receive(:multi_level?).and_return(true)
        expect(@q2).to receive(:level_count).and_return(3)
        expect(Answer).to receive(:new){ |attr| double(attr) }.exactly(3).times
        expect(@response.answer_sets[0].questioning).to eq @q1
        expect(@response.answer_sets[1].questioning).to eq @q2
        expect(@response.answer_sets[1].answers.map(&:rank)).to eq [1, 2, 3]
      end
    end
  end
end
