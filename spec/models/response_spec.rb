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
end
