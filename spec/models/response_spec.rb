require 'spec_helper'

describe Response do
  describe 'answer_sets' do
    before do
      @response = Response.new
      @q1, @q2 = double(level_count: 1), double(level_count: 3)
      @answers = [
        double(questioning: @q1, option_id: 10),
        double(questioning: @q2, rank: 1, option_id: 11),
        double(questioning: @q2, rank: 2, option_id: 12),
        double(questioning: @q2, rank: 3, option_id: 13)
      ]
      allow(@response).to receive(:answers).and_return(@answers)
      allow(@response).to receive(:visible_questionings).and_return([@q1, @q2])
    end

    context 'with no missing answers' do
      it 'should return answers grouped by questioning_id and sorted by rank' do
        expect(@response.answer_sets.map{|s| s.answers.map(&:option_id)}).to eq [[10], [11, 12, 13]]
      end
    end

    context 'with missing answer for multilevel question' do
      before do
        @answers.slice!(1,3)
      end

      it 'should build new answers' do
        expect(Answer).to receive(:new){ |attr| double(attr) }.exactly(3).times
        expect(@response.answer_sets[0].questioning).to eq @q1
        expect(@response.answer_sets[1].questioning).to eq @q2
        expect(@response.answer_sets[1].answers.map(&:rank)).to eq [1, 2, 3]
      end
    end

    context 'with partially answered multilevel question' do
      # new levels can be added after an answer is created. A new answer object should be created for these
      # levels even if the other levels are already answered.
      before do
        # Make q2 act like a 4 level question.
        allow(@q2).to receive(:level_count).and_return(4)
      end

      it 'should build proper answers' do
        expect(Answer).to receive(:new){ |attr| double(attr) }.exactly(1).times
        expect(@response.answer_sets[1].answers.map(&:rank)).to eq [1, 2, 3, 4]
      end
    end
  end

  describe 'answer_sets=' do
    before do
      @params = {
        '0' => { questioning_id: 1, value: '42' },
        '1' => {
          questioning_id: 2,
          answers: { '0' => { option_id: 12 }, '1' => { option_id: 14 } }
        }
      }
      @response = Response.new
    end

    context 'on create' do
      before do
        @answers = []
        allow(@response).to receive(:answers).and_return(@answers)
      end

      context 'with regular params' do
        it 'should work' do
          expect(@answers).to receive(:build).exactly(3).times
          @response.answer_sets = @params
        end
      end

      context 'with extra nil answer' do
        before do
          @params['1'][:answers]['2'] =  { option_id: nil }
        end

        it 'should discard the extra nil' do
          expect(@answers).to receive(:build).exactly(3).times
          @response.answer_sets = @params
        end
      end

      context 'with single nil answer' do
        before do
          @params['1'][:answers] = { '0' => { option_id: nil} }
        end

        it 'should not discard the answer' do
          expect(@answers).to receive(:build).exactly(2).times
          @response.answer_sets = @params
        end
      end
    end

    context 'on update' do
      before do
        @answers = [
          {questioning_id: 1, value: '42'},
          {questioning_id: 2, rank: 1, option_id: 12},
          {questioning_id: 2, rank: 2, option_id: 14}
        ]
        allow(@response).to receive(:answers).and_return(@answers)
      end

      it 'should replace all existing answers' do
        new_answers = { # Note shuffling - order shouldn't matter.
          '1' => {
            questioning_id: 2,
            answers: { '0' => { option_id: 22 }, '1' => { option_id: 24 } },
          },
          '0' => { questioning_id: 1, value: '43' },
        }
        # Each answer should get updated, regardless of order.
        expect(@answers[0]).to receive(:attributes=).with(questioning_id: 1, value: '43')
        expect(@answers[1]).to receive(:attributes=).with(questioning_id: 2, rank: 1, option_id: 22)
        expect(@answers[2]).to receive(:attributes=).with(questioning_id: 2, rank: 2, option_id: 24)
        @response.answer_sets = new_answers
      end
    end
  end
end
