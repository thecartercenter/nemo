# Tests the search functionality for the response model
require "spec_helper"
include SphinxSupport

describe Response do
  describe "search" do
    # Deliberately putting a period in form name here. This used to cause issues.
    let(:form) { create(:form, name: "foo 1.0", question_types: %w(integer)) }

    describe "form qualifier" do
      let(:form2) { create(:form, name: "bar", question_types: %w(integer)) }
      let!(:r1) { create(:response, form: form) }
      let!(:r2) { create(:response, form: form2) }
      let!(:r3) { create(:response, form: form) }

      it "should work" do
        assert_search(%{form:"foo 1.0"}, r1, r3)
      end
    end

    describe "submit_date qualifier" do
      let(:r1) { create(:response, form: form, created_at: "2017-01-01 22:00") }

      around do |example|
        in_timezone("Saskatchewan") { example.run }
      end

      it "should match dates in local timezone" do
        r1 # Ensure this gets built inside correct timezone now, not before the `around` executes.

        # Verify time stored in UTC (Jan 2), but search matches Jan 1.
        expect(SqlRunner.instance.run("SELECT created_at FROM responses")[0]["created_at"].day).to eq 2
        assert_search(%{submit-date:2017-01-01}, r1)
        assert_search(%{submit-date:2017-01-02})
      end
    end

    describe "full text search" do
      # Long text and short text question
      let!(:q1) { create(:question, qtype_name: "long_text", code: "mauve", add_to_form: form) }
      let!(:q2) { create(:question, qtype_name: "text", add_to_form: form) }

      # Two long text questions with explicit codes
      let!(:q3) { create(:question, qtype_name: "long_text", code: "blue", add_to_form: form) }
      let!(:q4) { create(:question, qtype_name: "long_text", code: "Green", add_to_form: form) }

      let!(:r1) do
        create(:response, form: form, reviewed: false, answer_values:
          [1, "the quick brown", "alpha", "apple bear cat", "dog earwax ipswitch"])
      end
      let!(:r2) do
        create(:response, form: form, reviewed: true, answer_values:
          [1, "fox heaven jumps", "bravo", "fuzzy gusher", "apple heaven ipswitch"])
      end
      let!(:r3) do
        create(:response, form: form, reviewed: true, answer_values:
          [1, "over bravo the lazy brown quick dog", "contour", "joker lumpy", "meal nexttime"])
      end

      # This is all in one test because sphinx is costly to setup and teardown
      it "should work", sphinx: true do
        do_sphinx_index

        # Answers qualifier should work with long_text questions
        assert_search("text:brown", r1, r3)

        # Answers qualifier should match short text questions and multiple questions
        assert_search("text:bravo", r2, r3)

        # Answers qualifier should be the default
        assert_search("quick brown", r1, r3)

        # Exact phrase matching should work
        assert_search(%{text:(quick brown)}, r1, r3) # Parenths don"t force exact phrase matching
        assert_search(%{text:"quick brown"}, r1)
        assert_search(%{"quick brown"}, r1)

        # Question codes should work as qualifiers
        assert_search("text:apple", r1, r2)
        assert_search("{blue}:apple", r1)
        assert_search("{Green}:apple", r2)

        # Invalid question codes should raise error
        assert_search("{foo}:bar", error: /'{foo}' is not a valid search qualifier./)

        # Using code from other mission should raise error
        # Create other mission and question
        other_mission = create(:mission, name: "other")
        create(:question, qtype_name: "long_text", code: "purple", mission: other_mission)
        assert_search("{purple}:bar", error: /valid search qualifier/)
        # Now create in the default mission and try again
        create(:question, qtype_name: "long_text", code: "purple")
        assert_search("{purple}:bar") # Should match nothing, but not error

        # Response should only appear once even if it has two matching answers
        assert_search("text:heaven", r2)

        # Multiple indexed qualifiers should work
        assert_search("{blue}:lumpy {Green}:meal", r3)
        assert_search("{blue}:lumpy {Green}:ipswitch")

        # Mixture of indexed and normal qualifiers should work
        assert_search("{Green}:ipswitch reviewed:1", r2)

        # Excerpts should be correct
        assert_excerpts("text:heaven", [
          [{questioning_id: form.questionings[1].id, code: "mauve", text: "fox {{{heaven}}} jumps"},
           {questioning_id: form.questionings[4].id, code: "Green", text: "apple {{{heaven}}} ipswitch"}]
        ])
        assert_excerpts("{green}:heaven", [
          [{questioning_id: form.questionings[4].id, code: "Green", text: "apple {{{heaven}}} ipswitch"}]
        ])
      end
    end

    def assert_search(query, *objs_or_error)
      if objs_or_error[0].is_a?(Hash)
        error_pattern = objs_or_error[0][:error]
        begin
          run_search(query)
        rescue
          assert_match(error_pattern, $!.to_s)
        else
          fail("No error was raised.")
        end
      else
        expect(run_search(query)).to eq(objs_or_error)
      end
    end

    # Runs a search with the given query and checks the returned excerpts
    def assert_excerpts(query, excerpts)
      responses = run_search(query, include_excerpts: true)
      expect(responses.size).to eq(excerpts.size)
      responses.each_with_index{|r,i| expect(r.excerpts).to eq(excerpts[i])}
    end

    def run_search(query, options = {})
      options[:include_excerpts] ||= false
      Response.do_search(Response.unscoped, query, {mission: get_mission}, options)
    end
  end
end
