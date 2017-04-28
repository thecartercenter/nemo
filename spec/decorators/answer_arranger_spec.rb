require "spec_helper"

describe AnswerArranger do

  let(:include_missing_answers) { false } # Overridden below
  let(:instance) { AnswerArranger.new(response, include_missing_answers: include_missing_answers).build }
  let(:nodes) { instance.nodes }

  context "general form" do
    let(:form) do
      _form = create(:form, question_types: [
        "select_one",
        "integer",
        "multilevel_select_one",
        {repeating: ["text", "multilevel_select_one", "integer"]},
        ["select_one", "select_multiple"],
        "decimal"
      ])
      # Make the first group repeatable.
      _form.children[4].update_attribute(:repeatable, true)
      _form
    end

    let(:response) do
      create(:response, form: form, answer_values: [
        "Cat",
        12,
        %w(Plant Tulip),
        [:repeating,
          ["stuff", %w(Animal Dog), 88],
          ["blah", %w(Animal Cat), 38]
        ],
        ["Dog", %w(Cat Dog)],
        3.2
      ])
    end

    it "should work" do
      expect(nodes[0]).to be_a AnswerNode
      expect(nodes[0].set).to be_a AnswerSet
      expect(nodes[0].set.answers[0]).to be_a Answer
      expect(nodes[3].instances[0]).to be_a AnswerInstance

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

    shared_examples_for "include blank answers" do
      it "should include blank answer set with question" do
        expect(nodes[0].set.answers[0].casted_value).to eq 123

        blank = nodes[1].set.answers[0]
        expect(blank).to be_new_record
        expect(blank.questioning).to eq form.children.last
        expect(blank.value).to be_nil
      end
    end

    shared_examples_for "don't include blank answers" do
      it "should not include blank answer set" do
        expect(nodes[0].set.answers[0].casted_value).to eq 123
        expect(nodes.size).to eq 1
      end
    end

    context "when question is visible" do
      context "when option is true" do
        let(:include_missing_answers) { true }
        it_should_behave_like "include blank answers"
      end

      context "when option is false" do
        let(:include_missing_answers) { false }
        it_should_behave_like "don't include blank answers"
      end
    end

    context "when question is hidden" do
      before do
        form.children.last.update_attribute(:hidden, true)
        form.reload
      end

      context "when option is true" do
        let(:include_missing_answers) { true }
        it_should_behave_like "don't include blank answers"
      end

      context "when option is false" do
        let(:include_missing_answers) { false }
        it_should_behave_like "don't include blank answers"
      end
    end
  end

  context "with answer to now-hidden question" do
    let(:form) { create(:form, question_types: %w(integer integer)) }
    let(:response) { create(:response, form: form, answer_values: [123, 456]) }

    before do
      form.children.last.update_attribute(:hidden, true)
      form.reload
    end

    it "should still include answer" do
      hidden = nodes[1].set.answers[0]
      expect(hidden.questioning).to eq form.children.last
      expect(hidden.casted_value).to eq 456
    end
  end

  context "with repeat group and include_missing_answers" do
    let(:form) do
      create(:form, question_types: ["integer", ["integer", "integer"], "integer"]).tap do |f|
        f.children[1].update_attribute(:repeatable, true)
      end
    end

    let(:response) do
      create(:response, form: form, answer_values: [
        123,
        [:repeating,
          [456, 789],
          [111, 222]
        ],
        333
      ])
    end

    let(:include_missing_answers) { true }

    it "should include blank instance" do
      expect(nodes[0].set.answers[0].casted_value).to eq 123

      expect(nodes[1].instances[0]).not_to be_placeholder
      expect(nodes[1].instances[0].nodes[0].set.answers[0].casted_value).to eq 456
      expect(nodes[1].instances[0].nodes[1].set.answers[0].casted_value).to eq 789

      expect(nodes[1].instances[1]).not_to be_placeholder
      expect(nodes[1].instances[1].nodes[0].set.answers[0].casted_value).to eq 111
      expect(nodes[1].instances[1].nodes[1].set.answers[0].casted_value).to eq 222

      expect(nodes[1].placeholder_instance).to be_placeholder
      expect(nodes[1].placeholder_instance.nodes[0].set.answers[0]).to be_new_record
      expect(nodes[1].placeholder_instance.nodes[1].set.answers[0]).to be_new_record
      expect(nodes[1].placeholder_instance.nodes[0].set.questioning_id).to eq(
        form.sorted_children[1].sorted_children[0].id)
      expect(nodes[1].placeholder_instance.nodes[1].set.questioning_id).to eq(
        form.sorted_children[1].sorted_children[1].id)

      # Last question
      expect(nodes[2].set.answers[0].casted_value).to eq 333
    end
  end

  context "with non-repeat group and include_missing_answers" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"], "integer"]) }
    let(:response) { create(:response, form: form, answer_values: [123, [456, 789], 333]) }
    let(:include_missing_answers) { true }

    it "should not include blank instance" do
      expect(nodes[0].set.answers[0].casted_value).to eq 123

      expect(nodes[1].instances[0]).not_to be_placeholder
      expect(nodes[1].instances[0].nodes[0].set.answers[0].casted_value).to eq 456
      expect(nodes[1].instances[0].nodes[1].set.answers[0].casted_value).to eq 789

      expect(nodes[1].placeholder_instance).to be_nil
    end
  end

  context "with no answers and new_record response and include_missing_answers" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"], "integer"]) }
    let(:response) { Response.new(form: form) }
    let(:include_missing_answers) { true }

    it "should include blank answers and a single instance with blank answers" do
      expect(nodes[0].set.answers[0]).to be_new_record

      # The instance is not considered a 'blank' instance in this case. It just has blank answers.
      expect(nodes[1].instances[0]).not_to be_placeholder
      expect(nodes[1].instances[0].nodes[0].set.answers[0]).to be_new_record
      expect(nodes[1].instances[0].nodes[1].set.answers[0]).to be_new_record

      expect(nodes[1].placeholder_instance).to be_nil

      expect(nodes[2].set.answers[0]).to be_new_record
    end
  end

  context "with no answers for a group and include_missing_answers false" do
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
