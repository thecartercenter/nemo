require "spec_helper"

describe Forms::ConditionComputer do
  let(:computer) { Forms::ConditionComputer.new(form) }

  context "with no conditions or skip rules" do
    let(:form) { create(:form, question_types: ["integer", "integer", ["integer", "integer"]]) }

    it "returns empty group for each question" do
      expect_condition_group(form.c[0], empty: true)
      expect_condition_group(form.c[1], empty: true)
      expect_condition_group(form.c[2], empty: true)
      expect_condition_group(form.c[2][0], empty: true)
      expect_condition_group(form.c[2][1], empty: true)
    end
  end

  context "with lots of conditions and skip rules" do
    let(:form) do
      create(:form, question_types: [
        "integer",
        "integer",
        "integer",
        ["integer", "integer", "integer"],
        "integer",
        ["integer", "integer", ["integer", "integer"]],
        "integer"
      ])
    end
    let(:form_items) { computer.preordered_form_items }

    # ConditionGroup doesn't really contain a _name attrib, but this can be useful
    # for debugging.
    let(:q3grp) { double(_name: :q3grp) }
    let(:q5grp) { double(_name: :q5grp) }
    let(:sr1grp) { double(_name: :sr1grp) }
    let(:sr2grp) { double(_name: :sr2grp) }
    let(:sr3grp) { double(_name: :sr3grp) }
    let(:sr4grp) { double(_name: :sr4grp) }
    let(:sr5grp) { double(_name: :sr5grp) }
    let(:sr6grp) { double(_name: :sr6grp) }
    let(:sr7grp) { double(_name: :sr7grp) }

    let(:sr1) do # Root to root
      build_skip_rule(form.c[0],
        destination: "item",
        dest_item: form.c[6])
    end

    let(:sr2) do # Root to group (not questioning)
      build_skip_rule(form.c[0],
        destination: "item",
        dest_item: form.c[3]) # This is a QingGroup
    end

    let(:sr3) do # Root to sub (this is a second SkipRule for form.c[1])
      build_skip_rule(form.c[1],
        destination: "item",
        dest_item: form.c[3].c[1])
    end

    let(:sr4) do # Sub to same sub
      build_skip_rule(form.c[3].c[0],
        destination: "item",
        dest_item: form.c[3].c[2])
    end

    let(:sr5) do # Sub to different sub
      build_skip_rule(form.c[3].c[1],
        destination: "item",
        dest_item: form.c[5].c[2].c[1])
    end

    let(:sr6) do # Sub to root
      build_skip_rule(form.c[3].c[2],
        destination: "item",
        dest_item: form.c[6])
    end

    let(:sr7) do # Sub to end
      build_skip_rule(form.c[5].c[2].c[0],
        destination: "end")
    end

    before do
      # Set display conditions on questions 3 and 5 (should be included with computed)
      allow(get_item(form.c[2])).to receive(:condition_group).and_return(q3grp)
      allow(get_item(form.c[2])).to receive(:display_conditionally?).and_return(true)
      allow(get_item(form.c[4])).to receive(:condition_group).and_return(q5grp)
      allow(get_item(form.c[4])).to receive(:display_conditionally?).and_return(true)

      allow(sr1).to receive(:condition_group).and_return(sr1grp)
      allow(sr2).to receive(:condition_group).and_return(sr2grp)
      allow(sr3).to receive(:condition_group).and_return(sr3grp)
      allow(sr4).to receive(:condition_group).and_return(sr4grp)
      allow(sr5).to receive(:condition_group).and_return(sr5grp)
      allow(sr6).to receive(:condition_group).and_return(sr6grp)
      allow(sr7).to receive(:condition_group).and_return(sr7grp)
    end

    # Table of expected conditions
    # NUM
    # Q1
    # Q2          SR1 SR2
    # Q3     DISP SR1 SR2 SR3
    # G4          SR1
    #  Q4.1               SR3
    #  Q4.2                   SR4
    #  Q4.3                       SR5
    # Q5     DISP SR1             SR5 SR6
    # G6          SR1                 SR6
    #  Q6.1                       SR5
    #  Q6.2                       SR5
    #  G6.3
    #   Q6.3.1                    SR5
    #   Q6.3.2                            SR7
    # Q7                                  SR7

    it "returns correct ConditionGroups" do
      expect_condition_group(form.c[0], empty: true)
      expect_condition_group(form.c[1], members: [sr1grp, sr2grp])
      expect_condition_group(form.c[2], members: [q3grp, sr1grp, sr2grp, sr3grp])
      expect_condition_group(form.c[3], members: [sr1grp])
      expect_condition_group(form.c[3].c[0], members: [sr3grp])
      expect_condition_group(form.c[3].c[1], members: [sr4grp])
      expect_condition_group(form.c[3].c[2], members: [sr5grp])
      expect_condition_group(form.c[4], members: [q5grp, sr1grp, sr5grp, sr6grp])
      expect_condition_group(form.c[5], members: [sr1grp, sr6grp])
      expect_condition_group(form.c[5].c[0], members: [sr5grp])
      expect_condition_group(form.c[5].c[1], members: [sr5grp])
      expect_condition_group(form.c[5].c[2], empty: true)
      expect_condition_group(form.c[5].c[2].c[0], members: [sr5grp])
      expect_condition_group(form.c[5].c[2].c[1], members: [sr7grp])
      expect_condition_group(form.c[6], members: [sr7grp])
    end
  end

  # Checks that the ConditionGroup returned for the given FormItem looks right
  # and has the expected member ConditionGroups.
  def expect_condition_group(form_item, members: [], empty: false)
    group = computer.condition_group_for(form_item)
    if empty
      expect(group).to be_empty
    else
      expect_group_with_members(group, members)
    end
  end

  def expect_group_with_members(group, members)
    expect(group.true_if).to eq "all_met"
    expect(group.negate?).to be false
    expect(group.members).to match_array(members)
  end

  def build_skip_rule(item, attribs)
    get_item(item).skip_rules.build(attribs)
  end

  # We get form item references this way because if we stub `item` directly
  # it will not be picked up by the Computer, because Computer iterates over a flat array
  # of items returned by form.preordered_items. These objects are distinct from those returned
  # by e.g. form.c[1]. Unfortunate! closure_tree has a way around this.
  def get_item(item)
    form_items.detect { |i| i.id == item.id }
  end
end
