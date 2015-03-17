require 'spec_helper'

describe Response do
  describe 'populate_from_hash' do
    before do
      @form = create(:form, question_types: %w(select_one multi_level_select_one select_multiple integer multi_level_select_one))
      @qs = @form.questions
      @cat = @qs[0].option_set.c[0]
      @plant = @qs[1].option_set.c[1]
      @oak = @qs[1].option_set.c[1].c[1]
      @cat2 = @qs[2].option_set.c[0]
      @dog2 = @qs[2].option_set.c[1]
      @animal = @qs[4].option_set.c[0]
    end

    it 'should work' do
      resp = Response.new(form: @form)
      resp.send(:populate_from_hash, {
        "q#{@qs[0].id}" => "on#{@cat.id}",
        "q#{@qs[1].id}_1" => "on#{@plant.id}",
        "q#{@qs[1].id}_2" => "on#{@oak.id}",
        "q#{@qs[2].id}" => "on#{@cat2.id} on#{@dog2.id}",
        "q#{@qs[3].id}" => '123',
        "q#{@qs[4].id}_1" => "on#{@animal.id}",
        "q#{@qs[4].id}_2" => 'none',
        })

      expect(resp.answer_sets[0].answers[0].option).to eq @cat.option
      expect(resp.answer_sets[0].answers[0].rank).to be_nil

      expect(resp.answer_sets[1].answers[0].option).to eq @plant.option
      expect(resp.answer_sets[1].answers[0].rank).to eq 1
      expect(resp.answer_sets[1].answers[1].option).to eq @oak.option
      expect(resp.answer_sets[1].answers[1].rank).to eq 2

      expect(resp.answer_sets[2].answers[0].choices.map(&:option)).to eq [@cat2.option, @dog2.option]
      expect(resp.answer_sets[2].answers[0].rank).to be_nil

      expect(resp.answer_sets[3].answers[0].value).to eq '123'
      expect(resp.answer_sets[3].answers[0].rank).to be_nil

      expect(resp.answer_sets[4].answers[0].option).to eq @animal.option
      expect(resp.answer_sets[4].answers[0].rank).to eq 1
      expect(resp.answer_sets[4].answers[1].option).to be_nil
      expect(resp.answer_sets[4].answers[1].rank).to eq 2
    end
  end
end
