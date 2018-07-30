require "rails_helper"

describe AnswerArranger do

  let(:placeholders) { :none } # Overridden below
  let(:instance) { AnswerArranger.new(response, placeholders: placeholders).build }
  let(:nodes) { instance.nodes }

  context "general form" do
    let(:form) do
      _form = create(:form, question_types: [
        "select_one",
        "integer",
        "multilevel_select_one",
        {repeating: {items: %w[text multilevel_select_one integer], name: "Repeat Group"}},
        %w[select_one select_multiple],
        "decimal"
      ])
      _form
    end

    let(:response) do
      create(:response, form: form, answer_values: [
        "Cat",
        12,
        %w[Plant Tulip],
        {repeating: [
          ["stuff", %w[Animal Dog], 88],
          ["blah", %w[Animal Cat], 38]
        ]},
        ["Dog", %w[Cat Dog]],
        3.2
      ])
    end

    it "should work" do
      expect(nodes[0]).to be_a OldAnswerNode
      expect(nodes[0].set).to be_a OldAnswerSet
      expect(nodes[0].set.answers[0]).to be_a Answer
      expect(nodes[3].instances[0]).to be_a OldAnswerInstance

      expect(nodes[0].set.answers[0].casted_value).to eq "Cat"

      expect(nodes[1].set.answers[0].casted_value).to eq 12

      expect(nodes[2].set.answers[0].casted_value).to eq "Plant"
      expect(nodes[2].set.answers[1].casted_value).to eq "Tulip"

      expect(nodes[3].instances[0].nodes[0].set.answers[0].casted_value).to eq "stuff"
      expect(nodes[3].instances[0].nodes[1].set.answers[0].casted_value).to eq "Animal"
      expect(nodes[3].instances[0].nodes[1].set.answers[1].casted_value).to eq "Dog"
      expect(nodes[3].instances[0].nodes[2].set.answers[0].casted_value).to eq 88

      expect(nodes[3].instances[1].nodes[0].set.answers[0].casted_value).to eq "blah"
      expect(nodes[3].instances[1].nodes[1].set.answers[0].casted_value).to eq "Animal"
      expect(nodes[3].instances[1].nodes[1].set.answers[1].casted_value).to eq "Cat"
      expect(nodes[3].instances[1].nodes[2].set.answers[0].casted_value).to eq 38

      expect(nodes[4].instances[0].nodes[0].set.answers[0].casted_value).to eq "Dog"
      expect(nodes[4].instances[0].nodes[1].set.answers[0].casted_value).to eq "Cat;Dog"

      expect(nodes[5].set.answers[0].casted_value).to eq 3.2
    end
  end

  context "with missing answer to visible question" do
    let(:form) { create(:form, question_types: %w(integer integer)) }
    let(:response) { create(:response, form: form, answer_values: [123]) }

    shared_examples_for "include placeholders" do
      it "should include blank answer set with question" do
        expect(nodes[0].set.answers[0].casted_value).to eq 123

        blank = nodes[1].set.answers[0]
        expect(blank).to be_new_record
        expect(blank.questioning).to eq form.sorted_children.last
        expect(blank.value).to be_nil
      end
    end

    shared_examples_for "don't include placeholders" do
      it "should not include blank answer set" do
        expect(nodes[0].set.answers[0].casted_value).to eq 123
        expect(nodes.size).to eq 1
      end
    end

    context "when question is visible" do
      context do
        let(:placeholders) { :all }
        it_should_behave_like "include placeholders"
      end

      context do
        let(:placeholders) { :except_repeats }
        it_should_behave_like "include placeholders"
      end

      context do
        let(:placeholders) { :none }
        it_should_behave_like "don't include placeholders"
      end
    end

    context "when question is hidden" do
      before do
        form.sorted_children.last.update_attribute(:hidden, true)
        form.reload
      end

      context do
        let(:placeholders) { :all }
        it_should_behave_like "don't include placeholders"
      end

      context do
        let(:placeholders) { :except_repeats }
        it_should_behave_like "don't include placeholders"
      end

      context do
        let(:placeholders) { :none }
        it_should_behave_like "don't include placeholders"
      end
    end
  end

  context "with answer to now-hidden question" do
    let(:form) { create(:form, question_types: %w(integer integer)) }
    let(:response) { create(:response, form: form, answer_values: [123, 456]) }

    before do
      form.sorted_children.last.update_attribute(:hidden, true)
      form.reload
    end

    it "should still include answer" do
      hidden = nodes[1].set.answers[0]
      expect(hidden.questioning).to eq form.sorted_children.last
      expect(hidden.casted_value).to eq 456
    end
  end

  context "with repeat group" do
    let(:form) do
      create(:form, question_types: ["integer", ["integer", "integer"], "integer"]).tap do |f|
        f.sorted_children[1].update_attribute(:repeatable, true)
      end
    end

    let(:response) do
      create(:response, form: form, answer_values: [
        123,
        {repeating: [
          [456, 789],
          [111, 222]
        ]},
        333
      ])
    end

    shared_examples_for "repeat group answers" do
      it do
        expect(nodes[0].set.answers[0].casted_value).to eq 123

        expect(nodes[1].instances[0]).not_to be_placeholder
        expect(nodes[1].instances[0].nodes[0].set.answers[0].casted_value).to eq 456
        expect(nodes[1].instances[0].nodes[1].set.answers[0].casted_value).to eq 789

        expect(nodes[1].instances[1]).not_to be_placeholder
        expect(nodes[1].instances[1].nodes[0].set.answers[0].casted_value).to eq 111
        expect(nodes[1].instances[1].nodes[1].set.answers[0].casted_value).to eq 222

        expect(nodes[2].set.answers[0].casted_value).to eq 333
      end
    end

    context "all placeholders" do
      let(:placeholders) { :all }

      it_should_behave_like "repeat group answers"

      it "should include placeholder instance" do
        expect(nodes[1].placeholder_instance).to be_placeholder
        expect(nodes[1].placeholder_instance.nodes[0].set.answers[0]).to be_new_record
        expect(nodes[1].placeholder_instance.nodes[1].set.answers[0]).to be_new_record
        expect(nodes[1].placeholder_instance.nodes[0].set.questioning_id).to eq(
          form.sorted_children[1].sorted_children[0].id)
        expect(nodes[1].placeholder_instance.nodes[1].set.questioning_id).to eq(
          form.sorted_children[1].sorted_children[1].id)
      end
    end

    context "placeholders except_repeats" do
      let(:placeholders) { :except_repeats }

      it_should_behave_like "repeat group answers"

      it "should not include placeholder instance" do
        expect(nodes[1].placeholder_instance).to be_nil
      end
    end

    context "no placeholders" do
      let(:placeholders) { :none }

      it_should_behave_like "repeat group answers"

      it "should not include placeholder instance" do
        expect(nodes[1].placeholder_instance).to be_nil
      end
    end
  end

  context "with non-repeat group" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"], "integer"]) }

    context "with full answers" do
      let(:response) { create(:response, form: form, answer_values: [123, [456, 789], 333]) }

      it do
        expect(nodes[0].set.answers[0].casted_value).to eq 123

        expect(nodes[1].instances[0]).not_to be_placeholder
        expect(nodes[1].instances[0].nodes[0].set.answers[0].casted_value).to eq 456
        expect(nodes[1].instances[0].nodes[1].set.answers[0].casted_value).to eq 789

        expect(nodes[1].placeholder_instance).to be_nil
      end
    end

    context "with no answers in group" do
      let(:response) { create(:response, form: form, answer_values: [123, nil, 333]) }

      context "placeholders except_repeats" do
        let(:placeholders) { :except_repeats }

        it "should not include placeholder_instance but should include instance with blank answers" do
          expect(nodes[0].set.answers[0].casted_value).to eq 123

          expect(nodes[1].instances[0]).not_to be_placeholder
          expect(nodes[1].instances[0].nodes[0].set.answers[0].casted_value).to be_nil
          expect(nodes[1].instances[0].nodes[1].set.answers[0].casted_value).to be_nil

          expect(nodes[1].placeholder_instance).to be_nil
        end
      end

      context "no placeholders" do
        let(:placeholders) { :none }

        it "should not include placeholder_instance or instance with blank answers" do
          expect(nodes[0].set.answers[0].casted_value).to eq 123
          expect(nodes[1].instances).to be_empty
          expect(nodes[1].placeholder_instance).to be_nil
        end
      end
    end
  end

  context "with no answers and new_record response and placeholders" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"], "integer"]) }
    let(:response) { Response.new(form: form) }
    let(:placeholders) { :all }

    it "should include answer placeholders and a single instance with answers placeholders" do
      expect(nodes[0].set.answers[0]).to be_new_record

      # The instance is not considered a 'blank' instance in this case. It just has blank answers.
      expect(nodes[1].instances[0]).not_to be_placeholder
      expect(nodes[1].instances[0].nodes[0].set.answers[0]).to be_new_record
      expect(nodes[1].instances[0].nodes[1].set.answers[0]).to be_new_record

      expect(nodes[1].placeholder_instance).to be_nil

      expect(nodes[2].set.answers[0]).to be_new_record
    end
  end

  context "with no answers for a group and no placeholders" do
    let(:form) { create(:form, question_types: ["integer"]) }
    let(:response) { create(:response, form: form, answer_values: [123]) }

    before do
      # Add a new group to form
      group = create(:qing_group, form: form)
      create(:questioning, form: form, parent: group)
    end

    it "should not create a node for the new group" do
      expect(nodes[0].set.answers[0].casted_value).to eq 123
      expect(nodes[1]).to be_nil
    end
  end
end
