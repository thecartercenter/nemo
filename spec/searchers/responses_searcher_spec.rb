# frozen_string_literal: true

require "rails_helper"

# Tests the search functionality for the response model
describe ResponsesSearcher do
  # Deliberately putting a period in form name here. This used to cause issues.
  let(:form) { create(:form, name: "foo 1.0", question_types: %w[integer]) }

  describe "form qualifier" do
    let(:form2) { create(:form, name: "bar", question_types: %w[integer]) }
    let!(:r1) { create(:response, form: form) }
    let!(:r2) { create(:response, form: form2) }
    let!(:r3) { create(:response, form: form) }

    it "should work" do
      expect(search(%(form:"foo 1.0"))).to contain_exactly(r1, r3)

      expect(searcher(%(form:"foo 1.0"))).to have_filter_data(form_ids: [form.id], advanced_text: "")
      expect(searcher(%(form:("foo 1.0" | bar)))).to have_filter_data(form_ids: [form2.id, form.id], advanced_text: "")
      expect(searcher(%(form:(foo bar)))).to have_filter_data(form_ids: [], advanced_text: "form:(foo bar)")
      expect(searcher(%(form:BAR))).to have_filter_data(form_ids: [form2.id], advanced_text: "")
      expect(searcher(%(form:x))).to have_filter_data(form_ids: [], advanced_text: "form:(x)")
      expect(searcher(%(form:bar source:x))).to have_filter_data(form_ids: [form2.id], advanced_text: "source:(x)")
    end
  end

  describe "reviewed qualifier" do
    let!(:r1) { create(:response, form: form, reviewed: true) }
    let!(:r2) { create(:response, form: form) }

    it "should work" do
      expect(search(%(reviewed:1))).to contain_exactly(r1)

      expect(searcher(%(reviewed:1))).to have_filter_data(is_reviewed: true, advanced_text: "")
      expect(searcher(%(reviewed:yes))).to have_filter_data(is_reviewed: true, advanced_text: "")
      expect(searcher(%(reviewed:"NO"))).to have_filter_data(is_reviewed: false, advanced_text: "")
      expect(searcher(%(reviewed:("0")))).to have_filter_data(is_reviewed: false, advanced_text: "")
      expect(searcher(%(reviewed:(1 0)))).to have_filter_data(is_reviewed: nil, advanced_text: "reviewed:(1 0)")
    end
  end

  describe "submit_date qualifier" do
    context "with tricky timezone" do
      let(:response) { create(:response, form: form, created_at: "2017-01-01 22:00") }

      it "should match dates in local timezone" do
        in_timezone("Saskatchewan") do
          response # Build response inside correct timezone.
          # Verify time stored in UTC (Jan 2), but search matches Jan 1.
          expect(SqlRunner.instance.run("SELECT created_at FROM responses")[0]["created_at"].day).to eq(2)
          expect(search(%(submit-date:2017-01-01))).to contain_exactly(response)
          expect(search(%(submit-date:2017-01-02))).to be_empty
        end
      end
    end

    context "with inequality operator" do
      let(:responses) do
        [
          create(:response, form: form, created_at: "2017-01-01 22:00"),
          create(:response, form: form, created_at: "2017-01-01 22:00"),
          create(:response, form: form, created_at: "2017-01-08 22:00")
        ]
      end

      it "should match correctly" do
        expect(search(%(submit-date < 2017-01-04))).to match_array(responses[0..1])
        expect(search(%(submit-date > 2017-01-04))).to contain_exactly(responses[2])
      end
    end
  end

  describe "submitter qualifier" do
    let!(:u1) { create(:user, name: "u1") }
    let!(:u2) { create(:user, name: "u2 name") }
    let!(:u3) { create(:user, name: "u3") }
    let!(:r1) { create(:response, user: u1) }
    let!(:r2) { create(:response, user: u2) }

    it "should work" do
      expect(search(%(submitter:#{u1.name}))).to contain_exactly(r1)

      expect(searcher(%(submitter:#{u1.name}))).to have_filter_data(submitters: items_by_name_and_id(u1), advanced_text: "")
      expect(searcher(%(submitter:(#{u1.name} | "#{u2.name}")))).to have_filter_data(submitters: items_by_name_and_id(u1, u2), advanced_text: "")
      expect(searcher(%(submitter:foo))).to have_filter_data(submitters: [], advanced_text: "submitter:(foo)")
      expect(searcher(%(submitter:foo source:x))).to have_filter_data(submitters: [], advanced_text: "submitter:(foo) source:(x)")
    end
  end

  describe "group qualifier" do
    let(:users) { create_list(:user, 3) }
    let(:group) { create(:user_group, name: "Fun Group") }
    let(:responses) { users.map { |u| create(:response, form: form, user: u) } }

    before do
      group.users = users[0..1]
      group.save!
    end

    it "should return responses from users in group" do
      expect(search(%(group:"fun group"))).to match_array(responses[0..1])
    end

    it "should return nothing for non-existent group" do
      expect(search(%(group:norble))).to be_empty
    end

    it "should parse searcher props" do
      expect(searcher(%(group:"fun group"))).to have_filter_data(groups: items_by_name_and_id(group), advanced_text: "")
      expect(searcher(%(group:foo))).to have_filter_data(groups: [], advanced_text: "group:(foo)")
      expect(searcher(%(group:foo source:x))).to have_filter_data(groups: [], advanced_text: "group:(foo) source:(x)")
    end
  end

  describe "question qualifier" do
    let!(:opt_set) { create(:option_set, option_names: :multilevel) }
    let!(:q1) { create(:question, qtype_name: "long_text", code: "blue", add_to_form: form) }
    let!(:q2) { create(:question, qtype_name: "long_text", code: "Green", add_to_form: form) }
    let!(:q3) do
      create(:question, qtype_name: "select_one", code: "red", option_set: opt_set, add_to_form: form)
    end

    let(:qing1) { qing_for_question(q1) } # {blue}
    let(:qing2) { qing_for_question(q2) } # {Green}
    let(:qing3) { qing_for_question(q3) } # {red}
    let(:node3) { OptionNode.find_by(option_set_id: opt_set.id) }

    it("should work") do
      expect(searcher(%(text:apple))).to have_filter_data(
        qings: [],
        advanced_text: "text:(apple)"
      )
      expect(searcher(%({blue}:apple))).to have_filter_data(
        qings: [{id: qing1.id, value: "apple"}],
        advanced_text: ""
      )
      expect(searcher(%({GREEN}:apple {blue}:apple text:apple))).to have_filter_data(
        qings: [{id: qing2.id, value: "apple"}, {id: qing1.id, value: "apple"}],
        advanced_text: "text:(apple)"
      )
      expect(searcher(%({red}:#{node3.option.canonical_name}))).to have_filter_data(
        qings: [{id: qing3.id, option_node_id: node3.id}],
        advanced_text: ""
      )
    end

    it("should handle translations") do
      node3.option.update!(name_fr: "Chat")

      expect(searcher(%({red}:chat))).to have_filter_data(
        qings: [{id: qing3.id, option_node_id: node3.id}],
        advanced_text: ""
      )
    end
  end

  describe "full text search" do
    let!(:q1) { create(:question, qtype_name: "long_text", code: "mauve", add_to_form: form) }
    let!(:q2) { create(:question, qtype_name: "text", add_to_form: form) }
    let!(:q3) { create(:question, qtype_name: "long_text", code: "blue", add_to_form: form) }
    let!(:q4) { create(:question, qtype_name: "long_text", code: "Green", add_to_form: form) }
    let!(:q5) { create(:question, qtype_name: "select_one", code: "Pink", add_to_form: form) }
    let!(:q6) do
      create(:question, qtype_name: "select_multiple", code: "Brown",
                        option_names: %w[hammer wrench screwdriver], add_to_form: form)
    end
    let!(:r1) do
      create(:response, form: form, reviewed: false, answer_values:
        [1, "the quick brown", "alpha", "apple bear cat", "dog earwax ipswitch", "Cat", ["hammer"]])
    end
    let!(:r2) do
      create(:response, form: form, reviewed: true, answer_values:
        [1, "fox heaven jumps", "bravo", "fuzzy gusher", "apple heaven ipswitch", "Dog", %w[hammer wrench]])
    end
    let!(:r3) do
      create(:response, form: form, reviewed: true, answer_values:
        [1, "over bravo the lazy brown quick dog", "contour", "joker lumpy", "meal nexttime", "Cat", []])
    end

    before do
      # Add option names a different languages
      q5.option_set.c[0].option.update!(name_fr: "chat")
      q6.option_set.c[0].option.update!(name_fr: "marteau")
    end

    it "should work" do
      expect(search("text:brown")).to contain_exactly(r1, r3)
      expect(search("text:bravo")).to contain_exactly(r2, r3)
      expect(search("cat")).to contain_exactly(r1, r3)
      expect(search("chat")).to contain_exactly(r1, r3)
      expect(search("wrench")).to contain_exactly(r2)

      # Answers qualifier should be the default
      expect(search("quick brown")).to contain_exactly(r1, r3)

      # Exact phrase matching should work
      # Parentheses don't force exact phrase matching
      expect(search(%{text:(quick brown)})). to contain_exactly(r1, r3)

      # TODO: FIX EXACT PHRASE MATCHING
      # expect(search(%{text:"quick brown"}, r1)
      # expect(search(%{"quick brown"}, r1)

      # Question codes should work as qualifiers
      expect(search("text:apple")).to contain_exactly(r1, r2)
      expect(search("{blue}:apple")).to contain_exactly(r1)
      expect(search("{Green}:apple")).to contain_exactly(r2)

      # Searching for option names should work in any language
      expect(search("{Pink}:dog")).to contain_exactly(r2)
      expect(search("{Brown}:hammer")).to contain_exactly(r1, r2)
      expect(search("{Brown}:marteau")).to contain_exactly(r1, r2)
      expect(search("{Brown}:wrench")).to contain_exactly(r2)

      # Invalid question codes should raise error
      expect { search("{foo}:bar") }.to raise_error(/'{foo}' is not a valid search qualifier./)

      # Using code from other mission should raise error
      # Create other mission and question
      other_mission = create(:mission, name: "other")
      create(:question, qtype_name: "long_text", code: "purple", mission: other_mission)
      expect { search("{purple}:bar") }.to raise_error(/valid search qualifier/)
      # Now create in the default mission and try again
      create(:question, qtype_name: "long_text", code: "purple")
      expect(search("{purple}:bar")).to be_empty # Should match nothing, but not error

      # Response should only appear once even if it has two matching answers
      expect(search("text:heaven")).to contain_exactly(r2)

      # Multiple indexed qualifiers should work
      expect(search("{blue}:lumpy {Green}:meal")).to contain_exactly(r3)
      expect(search("{blue}:lumpy {Green}:ipswitch")).to be_empty

      # Mixture of indexed and normal qualifiers should work
      expect(search("{Green}:ipswitch reviewed:1")).to contain_exactly(r2)
    end
  end

  RSpec::Matchers.define(:have_filter_data) do |expected|
    match do |actual|
      actual.apply
      @actual = expected.keys.map { |k| [k, actual.send(k)] }.to_h
      @actual == expected
    end

    diffable
  end

  def search(query)
    searcher(query).apply
  end

  def searcher(query)
    ResponsesSearcher.new(relation: Response, query: query, scope: {mission: get_mission})
  end

  def items_by_name_and_id(*items)
    items.pluck(:id, :name).map { |id, name| {id: id, name: name} }
  end

  def qing_for_question(question)
    FilterDataController.filter_unique(Questioning.where(question: question)).first
  end
end
