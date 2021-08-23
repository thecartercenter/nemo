# frozen_string_literal: true

require "rails_helper"

# Tests the search functionality for the response model
describe ResponsesSearcher do
  # Deliberately putting a period in form name here. This used to cause issues.
  let(:form) { create(:form, name: "foo 1.0", question_types: %w[integer]) }

  describe "form qualifier" do
    let(:form2) { create(:form, name: "bar", question_types: %w[integer]) }
    let(:form3) { create(:form, name: "qu'o`t\"es") }
    let!(:r1) { create(:response, form: form) }
    let!(:r2) { create(:response, form: form2) }
    let!(:r3) { create(:response, form: form) }
    let!(:r4) { create(:response, form: form3) }

    it "matches the correct objects" do
      expect(search(%(form:"foo 1.0"))).to contain_exactly(r1, r3)
      expect(search(%(form:(qu'o`t"es)))).to contain_exactly(r4)
      expect(search(%(form-id:"#{form.id}"))).to contain_exactly(r1, r3)
    end

    it "has correct filter data" do
      expect(searcher(%(form:"foo 1.0"))).to have_filter_data(
        form_ids: [],
        advanced_text: "form:(\"foo 1.0\")"
      )
      expect(searcher(%(form-id:"#{form.id}"))).to have_filter_data(form_ids: [form.id])
      expect(searcher(%(form-id:("#{form.id}" | #{form2.id})))).to have_filter_data(
        form_ids: [form2.id, form.id]
      )
      expect(searcher(%(form-id:"#{form.id}" source:x))).to have_filter_data(
        form_ids: [form.id],
        advanced_text: "source:x"
      )
    end
  end

  describe "reviewed qualifier" do
    let!(:r1) { create(:response, form: form, reviewed: true) }
    let!(:r2) { create(:response, form: form) }

    it "matches the correct objects" do
      expect(search(%(reviewed:1))).to contain_exactly(r1)
    end

    it "has correct filter data" do
      expect(searcher(%(reviewed:1))).to have_filter_data(is_reviewed: true)
      expect(searcher(%(reviewed:yes))).to have_filter_data(is_reviewed: true)
      expect(searcher(%(reviewed:"NO"))).to have_filter_data(is_reviewed: false)
      expect(searcher(%(reviewed:("0")))).to have_filter_data(is_reviewed: false)
      expect(searcher(%(reviewed:(1 0)))).to have_filter_data(is_reviewed: nil,
                                                              advanced_text: "reviewed:(1 0)")
    end
  end

  describe "submit_date qualifier" do
    context "with tricky timezone" do
      let(:response) { create(:response, form: form, created_at: "2017-01-01 22:00") }

      it "matches dates in local timezone" do
        in_timezone("Saskatchewan") do
          response # Build response inside correct timezone.
          # Verify time stored in UTC (Jan 2), but search matches Jan 1.
          expect(SqlRunner.instance.run("SELECT created_at FROM responses")[0]["created_at"].day).to eq(2)
          expect(search(%(submit-date:2017-01-01))).to contain_exactly(response)
          expect(search(%(submit-date:2017-01-02))).to be_empty
        end
      end
    end

    context "with mulutiple responses" do
      let(:responses) do
        [
          create(:response, form: form, created_at: "2017-01-01 22:00"),
          create(:response, form: form, created_at: "2017-01-01 22:00"),
          create(:response, form: form, created_at: "2017-01-08 22:00")
        ]
      end

      it "matches the correct objects" do
        expect(search(%(submit-date < 2017-01-04))).to match_array(responses[0..1])
        expect(search(%(submit-date > 2017-01-04))).to contain_exactly(responses[2])
        expect(search(%(submit-date:2017-01-08))).to contain_exactly(responses[2])
      end

      it "has correct filter data" do
        expect(searcher(%(submit-date <= 2017-01-04))).to have_filter_data(
          start_date: nil, end_date: Date.new(2017, 1, 4)
        )
        expect(searcher(%(submit-date:2017-01-08))).to have_filter_data(
          start_date: Date.new(2017, 1, 8), end_date: Date.new(2017, 1, 8)
        )
        complex = %(submit-date > 2017-01-31 submit-date > 2017-01-02
                    submit-date <= 2017-03-05 submit-date <= 2017-02-28)
        expect(searcher(complex)).to have_filter_data(
          start_date: Date.new(2017, 2, 1), end_date: Date.new(2017, 2, 28)
        )
      end

      it "handles bad date gracefullly" do
        expect { search(%(submit-date < 2017-14-04)) }.to raise_error(/is not a valid date/)
      end
    end
  end

  describe "submitter qualifier" do
    let!(:u1) { create(:user, name: "u1") }
    let!(:u2) { create(:user, name: "u2 name") }
    let!(:u3) { create(:user, name: "u3") }
    let!(:r1) { create(:response, user: u1) }
    let!(:r2) { create(:response, user: u2) }

    it "matches the correct objects" do
      expect(search(%(submitter:#{u1.name}))).to contain_exactly(r1)
      expect(search(%(submitter-id:#{u1.id}))).to contain_exactly(r1)
    end

    it "has correct filter data" do
      expect(searcher(%(submitter:#{u1.name}))).to have_filter_data(
        submitters: [],
        advanced_text: "submitter:#{u1.name}"
      )
      expect(searcher(%(submitter-id:#{u1.id}))).to have_filter_data(
        submitters: [{id: u1.id, name: u1.name}]
      )
      expect(searcher(%(submitter-id:(#{u1.id} | "#{u2.id}") source:x))).to have_filter_data(
        submitters: [{id: u1.id, name: u1.name}, {id: u2.id, name: u2.name}],
        advanced_text: "source:x"
      )
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
      expect(search(%(group-id:"#{group.id}"))).to match_array(responses[0..1])
    end

    it "should return nothing for non-existent group" do
      expect(search(%(group:norble))).to be_empty
    end

    it "should parse searcher props" do
      expect(searcher(%(group:"fun group"))).to have_filter_data(
        groups: [],
        advanced_text: "group:(\"fun group\")"
      )
      expect(searcher(%(group-id:#{group.id} source:x))).to have_filter_data(
        groups: [{id: group.id, name: group.name}],
        advanced_text: "source:x"
      )
    end
  end

  describe "question qualifier" do
    let(:form) { create(:form, question_types: %w[long_text long_text multilevel_select_one]) }
    let(:form2) { create(:form) }
    let(:codes) { form.c[0..2].map(&:code) }
    let(:node3) { form.c[2].question.option_set.c[0] }

    before do
      form.mission.setting.update!(preferred_locales_str: "en,fr")
    end

    it "has correct filter data" do
      expect(searcher(%(apple))).to have_filter_data(
        qings: [],
        advanced_text: "apple"
      )
      expect(searcher(%({#{codes[0]}}:apple))).to have_filter_data(
        qings: [{id: form.c[0].id, value: "apple"}]
      )
      expect(searcher(%({#{codes[1].upcase}}:apple {#{codes[0].downcase}}:apple apple))).to have_filter_data(
        qings: [{id: form.c[1].id, value: "apple"}, {id: form.c[0].id, value: "apple"}],
        advanced_text: "apple"
      )
      expect(searcher(%({#{codes[0]}}:apple form-id:"#{form2.id}"))).to have_filter_data(
        # This question doesn't exist on this form, so it won't be found.
        qings: [{id: nil, value: "apple"}]
      )
      expect(searcher(%({#{codes[0]}}:apple form-id:"#{form.id}"))).to have_filter_data(
        # But it does exist on this form.
        qings: [{id: form.c[0].id, value: "apple"}]
      )
      expect(searcher(%({#{codes[2]}}:#{node3.option.canonical_name}))).to have_filter_data(
        qings: [{id: form.c[2].id, option_node_id: node3.id, option_node_value: node3.option.canonical_name}]
      )
    end

    it "should handle translations" do
      node3.option.update!(name_fr: "Chat")

      expect(searcher(%({#{codes[2]}}:chat))).to have_filter_data(
        qings: [{id: form.c[2].id, option_node_id: node3.id, option_node_value: "chat"}]
      )
    end
  end

  describe "full text search" do
    let!(:q1) { create(:question, qtype_name: "long_text", code: "mauve", add_to_form: form) }
    let!(:q2) { create(:question, qtype_name: "text", add_to_form: form) }
    let!(:q3) { create(:question, qtype_name: "long_text", code: "blue", add_to_form: form) }
    let!(:q4) { create(:question, qtype_name: "long_text", code: "Green", add_to_form: form) }
    let!(:q_select_one) { create(:question, qtype_name: "select_one", code: "Pink", add_to_form: form) }
    let!(:q_select_multiple) do
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
      node = q_select_one.option_set.c[0]
      node.update!(option_attribs: {id: node.option_id,
                                    name_translations: {name_en: "Cat", name_fr: "chat"}})
      node = q_select_multiple.option_set.c[0]
      node.update!(option_attribs: {id: node.option_id,
                                    name_translations: {name_en: "hammer", name_fr: "marteau"}})
    end

    it "matches the correct objects" do
      expect(search("text:brown")).to contain_exactly(r1, r3)
      expect(search("text:bravo")).to contain_exactly(r2, r3)
      expect(search("cat")).to contain_exactly(r1, r3)
      expect(search("chat")).to contain_exactly(r1, r3)
      expect(search("wrench")).to contain_exactly(r2)

      # Answers qualifier should be the default
      expect(search("quick brown")).to contain_exactly(r1, r3)

      # Exact phrase matching should work
      # Parentheses don't force exact phrase matching
      expect(search(%{text:(quick brown)})).to contain_exactly(r1, r3)

      # TODO: Fix exact phrase matching: https://github.com/Casecommons/pg_search/issues/345
      # expect(search(%(text:"quick brown"))).to contain_exactly(r1)
      # expect(search(%("quick brown"))).to contain_exactly(r1)

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

  describe "special non-text search" do
    let!(:q1) { create(:question, qtype_name: "date", code: "date", add_to_form: form) }
    let!(:q2) { create(:question, qtype_name: "time", code: "time", add_to_form: form) }
    let!(:q3) { create(:question, qtype_name: "datetime", code: "datetime", add_to_form: form) }
    let!(:r1) do
      create(:response, form: form, reviewed: false, answer_values:
        [1, "2021-01-01", "12:00:00", "2021-01-01 12:00:00"])
    end
    let!(:r2) do
      create(:response, form: form, reviewed: true, answer_values:
        [1, "2020-12-31", "12:00:01", "2020-12-31 12:00:01"])
    end
    let!(:r3) do
      create(:response, form: form, reviewed: true, answer_values:
        [1, nil, nil, nil])
    end

    it "matches the correct objects" do
      expect(search("{date}:2021-01-01")).to contain_exactly(r1)
      expect(search("{time}:12h00m00s")).to contain_exactly(r1)
      expect(search("{datetime}:2021-01-01 12h00m00s")).to contain_exactly(r1)
      expect(search("{datetime}:2021 12h")).to contain_exactly(r1) # Partial string match also works
      expect(search("12h00m")).to contain_exactly(r1, r2) # Or just plaintext search
    end

    it "respects updated values" do
      expect(search("{date}:2021-01-01")).to contain_exactly(r1)
      r1.c[1].update!(date_value: Date.parse("2022-02-02"))
      expect(search("{date}:2021-01-01")).to be_empty
      expect(search("{date}:2022-02-02")).to contain_exactly(r1)
    end
  end

  describe "default text qualifier" do
    let!(:q1) { create(:question, qtype_name: "long_text", add_to_form: form) }
    let!(:q2) { create(:question, qtype_name: "text", add_to_form: form) }
    let!(:r1) { create(:response, form: form, answer_values: [1, "foo bar", "foo"]) }
    let!(:r2) { create(:response, form: form, answer_values: [1, "baz", "qux"]) }

    it "matches the correct objects" do
      expect(search("foo")).to contain_exactly(r1)
      expect(search("bar bar")).to contain_exactly(r1)
      expect(search("foo baz")).to contain_exactly
    end

    it "has correct filter data" do
      expect(searcher("foo")).to have_filter_data(advanced_text: "foo")
      expect(searcher("text:foo")).to have_filter_data(advanced_text: "foo")
      expect(searcher("text=it's")).to have_filter_data(advanced_text: "it's")
      expect(searcher("bar bar")).to have_filter_data(advanced_text: "bar bar")
      expect(searcher("reviewed:1 foo")).to have_filter_data(advanced_text: "foo")
      expect(searcher("foo reviewed:1 123.4 source:(x)")).to have_filter_data(
        advanced_text: "foo 123.4 source:x"
      )
      expect(searcher("source:(\"x y\" z)")).to have_filter_data(advanced_text: "source:(\"x y\" z)")
    end
  end

  RSpec::Matchers.define(:have_filter_data) do |expected|
    match do |actual|
      expected[:advanced_text] ||= ""
      actual.apply
      @actual = expected.keys.index_with { |k| actual.send(k) }
      @actual = @actual.values.map(&method(:safe_sort))
      expected = expected.values.map(&method(:safe_sort))
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

  def safe_sort(object)
    object.respond_to?(:sort_by) ? object.sort_by(&:hash) : object
  end
end
