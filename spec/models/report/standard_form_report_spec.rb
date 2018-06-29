# There are more report tests in test/unit/report.
require "rails_helper"

describe Report::StandardFormReport do
  context "basic" do
    before do
      @new_report = Report::StandardFormReport.new
    end

    it "form_id should default to nil" do
      expect(@new_report.form_id).to be_nil
    end

    it "question_order should default to number" do
      expect(@new_report.question_order).to eq("number")
    end

    it "text_responses should default to all" do
      expect(@new_report.text_responses).to eq("all")
    end

    it "form foreign key should work" do
      @new_report.form = create(:form)
      expect(@new_report.form).not_to be_nil
    end

    it "should return correct response count" do
      build_form_and_responses
      build_and_run_report
      expect(@report.response_count).to eq(5)
    end

    it "should return correct response count for a coordinator" do
      coordinator = get_user
      ability = Ability.new(user: coordinator, mission: get_mission)

      build_form_and_responses

      @report = create(:standard_form_report, form: @form)
      @report.run(ability)

      expect(@report.response_count).to eq(5)
    end

    it "should return correct response count for an enumerator" do
      enumerator = create(:user, role_name: :enumerator)
      ability = Ability.new(user: enumerator, mission: get_mission)

      build_form_and_responses

      @report = create(:standard_form_report, form: @form)
      @report.run(ability)

      expect(@report.response_count).to eq(0)
    end

    it "should not contain invisible questionings" do
      build_form_and_responses

      # make one question invisible
      @form.questionings[1].update_attributes!(hidden: true)

      build_and_run_report

      expect(@report.subsets[0].summaries.map(&:questioning).include?(@form.questionings[1])).to be_falsey, "summaries should not contain hidden question"
    end

    it "should return summaries matching questions" do
      build_form_and_responses
      build_and_run_report
      expect(@report.subsets[0].summaries[2].qtype.name).to eq("decimal")

      # We leave out the last questioning on the form since location questions should not be included.
      expect(@report.subsets[0].summaries.map(&:questioning)).to eq(@form.questionings[0..3])
    end

    it "should return non-submitting enumerators" do
      enumerators = %w(bob jojo cass sal toz).map do |n|
        create(:user, login: n, role_name: :enumerator, name: n.capitalize)
      end

      # Make decoy coord and admin users
      coord = create(:user, role_name: :coordinator)
      admin = create(:user, role_name: :enumerator, admin: true)

      # Make simple form and add responses from first two users
      @form = create(:form)
      enumerators[0...2].each { |o| create(:response, form: @form, user: o) }

      build_and_run_report

      # Check missing enumerators
      missing_enumerators = @report.users_without_responses(role: :enumerator, limit: 10)
      expect(missing_enumerators.map(&:login).sort).to eq(%w(cass sal toz))
      expect(@report.enumerators_without_responses).to eq("Cass, Sal, Toz")

      # Change constant size to check mission enumerators summarization
      stub_const("Report::StandardFormReport::MISSING_OBSERVERS_SIZE_LIMIT", 2)
      expect(@report.enumerators_without_responses).to eq("Cass, Sal, ... (Clipped)")
    end

    it "empty? should be false if responses" do
      build_form_and_responses
      build_and_run_report
      expect(@report.empty?).to be_falsey, "report should not be empty"
    end

    it "empty? should be true if no responses" do
      build_form_and_responses(response_count: 0)
      build_and_run_report
      expect(@report.empty?).to be_truthy, "report should be empty"
    end

    it "empty? should be true if no questions" do
      @form = create(:form)
      build_and_run_report
      expect(@report.empty?).to be_truthy, "report should be empty"
    end

    it "with numeric question order should have single summary group" do
      build_form_and_responses
      build_and_run_report # defaults to numeric order
      expect(@report.subsets[0].tag_groups[0].type_groups.size).to eq(1)
      expect(@report.subsets[0].tag_groups[0].type_groups[0].type_set).to eq("all")
    end
  end

  context "on destroy" do
    before do
      @form = create(:form, question_types: %w(select_one integer))
      @report = create(:standard_form_report, form: @form, disagg_qing: @form.questionings[1])
    end

    it "should have disagg_qing nullified when questioning destroyed" do
      @form.questionings[1].destroy
      expect(@report.reload.disagg_qing).to be_nil
    end

    it "should be destroyed when form destroyed" do
      @form.destroy
      expect(Report::Report.exists?(@report.id)).to be false
    end
  end

  describe "cache_key" do
    let(:report) { create(:standard_form_report) }

    it "should be correct" do
      expect(report.cache_key).to match(
        %r{\Areport/standard_form_reports/.+//calcs-0-/none\z})
    end
  end

  def build_form_and_responses(options = {})
    @form = create(:form, question_types: %w(integer integer decimal select_one location))
    (options[:response_count] || 5).times do
      create(:response, form: @form, answer_values: [1, 2, 1.5, "Cat", nil])
    end
  end

  def build_and_run_report
    # assume we are running as admin
    @user = create(:user, admin: true)
    @report = create(:standard_form_report, form: @form)
    @report.run(Ability.new(user: @user, mission: get_mission))
  end
end
