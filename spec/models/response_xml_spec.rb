require "spec_helper"

describe Response do
  describe "populate_from_hash" do
    before do
      @form = create(:form, question_types: %w(select_one multilevel_select_one select_multiple integer multilevel_select_one))
      @qs = @form.questions
      @qings = @form.questionings
      @cat = @qs[0].option_set.c[0]
      @plant = @qs[1].option_set.c[1]
      @oak = @qs[1].option_set.c[1].c[1]
      @cat2 = @qs[2].option_set.c[0]
      @dog2 = @qs[2].option_set.c[1]
      @animal = @qs[4].option_set.c[0]
    end

    it "should work" do
      resp = build(:response, form: @form, mission: @form.mission)
      resp.send(:populate_from_hash, {
        "q#{@qs[0].id}" => "on#{@cat.id}",
        "q#{@qs[1].id}_1" => "on#{@plant.id}",
        "q#{@qs[1].id}_2" => "on#{@oak.id}",
        "q#{@qs[2].id}" => "on#{@cat2.id} on#{@dog2.id}",
        "q#{@qs[3].id}" => "123",
        "q#{@qs[4].id}_1" => "on#{@animal.id}",
        "q#{@qs[4].id}_2" => "none",
      })
      resp.save!

      nodes = AnswerArranger.new(resp).build.nodes

      expect(nodes[0].set.answers[0].option).to eq @cat.option
      expect(nodes[0].set.answers[0].rank).to eq 1

      expect(nodes[1].set.answers[0].option).to eq @plant.option
      expect(nodes[1].set.answers[0].rank).to eq 1
      expect(nodes[1].set.answers[1].option).to eq @oak.option
      expect(nodes[1].set.answers[1].rank).to eq 2

      expect(nodes[2].set.answers[0].choices.map(&:option)).to eq [@cat2.option, @dog2.option]
      expect(nodes[2].set.answers[0].rank).to eq 1

      expect(nodes[3].set.answers[0].value).to eq "123"
      expect(nodes[3].set.answers[0].rank).to eq 1

      expect(nodes[4].set.answers[0].option).to eq @animal.option
      expect(nodes[4].set.answers[0].rank).to eq 1
      expect(nodes[4].set.answers[1].option).to be_nil
      expect(nodes[4].set.answers[1].rank).to eq 2
    end
  end
end
