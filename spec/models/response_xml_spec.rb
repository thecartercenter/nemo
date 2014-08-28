require 'spec_helper'

describe Response do
  describe 'populate_from_hash' do
    before do
      @form = create(:sample_form)
      @cat = @form.questions[0].options[0]
      @plant = @form.questions[1].option_set.root_node.c[1].option
      @oak = @form.questions[1].option_set.root_node.c[1].c[1].option
    end

    it 'should work' do
      resp = Response.new(form: @form)
      resp.send(:populate_from_hash, {
        'q1' => @cat.id.to_s,
        'q2' => @plant.id.to_s,
        'q3' => '123'
      })

      expect(resp.answer_sets[0].answers[0].option).to eq @cat
      expect(resp.answer_sets[1].answers[0].option).to eq @plant
      expect(resp.answer_sets[2].answers[0].value).to eq '123'
    end
  end
end
