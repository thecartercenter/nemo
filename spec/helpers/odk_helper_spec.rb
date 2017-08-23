require 'spec_helper'

describe OdkHelper do
  it "#required_value returns true for forms that don't allow incomplete responses" do
    f = create(:form, allow_incomplete: false)
    expect(helper.required_value(f)).to eq('true()')
  end

  it "#required_value returns ODK select statement for forms that allow incomplete responses" do
    f = create(:form, allow_incomplete: true)
    expect(helper.required_value(f)).to eq("selected\(/data/#{OdkHelper::IR_QUESTION}, 'no')")
  end

  context "#get_element_from_xml_name" do

    let(:form) do
      form = create(:form, :published, :with_version,
        name: "Nested Repeat Group",
        version: "abc",
        question_types: [
          {repeating:
            {
              items:
                ["text", #q1
                  "multilevel_select_one", #q2
                  {
                    repeating:
                      {
                        items: ["integer", "integer"], #q3,q4
                        name: "Repeat Group A"
                      }
                  },
                  "long_text" #q5
                ],
                name: "Repeat Group 1"
            }
          },
          "text", #q6
           {
            repeating: {
              items: ["text"], #q7
              name: "Repeat Group 2"
            }
          }
        ]
      )
    end

    it "returns correct group" do
      group = form.sorted_children[2] #group 2
      expect(group.group_name_en).to eq "Repeat Group 2"
      tag_name = "grp#{group.id}"
      result = helper.get_element_from_tag_name(tag_name, form.root_group.sorted_children)
      expect(result.uuid).to eq group.uuid
    end

    it "returns correct questioning" do
      questioning = form.root_group.sorted_children[1]
      tag_name = "q#{questioning.question.id}"
      result = helper.get_element_from_tag_name(tag_name, form.root_group.sorted_children)
      expect(result.uuid).to eq questioning.uuid
    end

    xit "returns correct subquestion for multilevel" do
      # multilevel_question = form.root_group.sorted_children[0].sorted_children[1]
      # expect(multilevel_question.multilevel?).to be true
      # subquestion = multilevel_question.subquestions[1]
      # tag_name = "q#{multilevel_question.id}_#{subquestion.rank}"
      #
      # result = helper.get_element_from_tag_name(tag_name, multilevel_question.subquestions)
      # expect(result.question.id).to eq multilevel_question.id
      # expect(result.rank).to eq subquestion.rank

    end

    it "returns nil if no matching element" do

    end
  end
end
