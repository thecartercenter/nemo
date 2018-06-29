# There are more report tests in test/unit/report.
require 'rails_helper'

describe Report::AnswerTallyReport do
  include_context "reports"

  shared_examples_for 'basic stuff' do
    describe 'destroy' do
      before do
        # Reloading here was the only way to reproduce a stack level too deep bug.
        @report.reload
        @report.destroy
      end

      it 'should work' do
        expect(@report).to be_destroyed
      end
    end
  end

  context 'with specific questions' do
    before do
      @form = create(:form, question_types: %w(select_one))
      @report = create(:answer_tally_report, _calculations: [@form.questions[0]], run: true)
    end

    it_behaves_like 'basic stuff'
  end

  context 'with option sets' do
    before do
      @option_set1 = create(:option_set)
      @option_set2 = create(:option_set)
      @report = create(:answer_tally_report, option_sets: [@option_set1, @option_set2], run: true)
    end

    it_behaves_like 'basic stuff'

    context 'when related option set destroyed' do
      before do
        @option_set1.destroy
      end

      it 'should not be destroyed but should no longer reference the destroyed set' do
        expect(Report::Report.exists?(@report.id)).to be true
        expect(@report.reload.option_sets).to eq [@option_set2]
      end
    end

    context 'when last related option set destroyed' do
      before do
        @option_set1.destroy
        @option_set2.destroy
      end

      it 'should destroy self' do
        expect(Report::Report.exists?(@report.id)).to be false
      end
    end
  end

  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(multilevel_select_one))
      create(:response, form: @form, answer_values: [['Animal', 'Cat']])
      create(:response, form: @form, answer_values: [['Animal', 'Dog']])
      create(:response, form: @form, answer_values: [['Animal']])
      create(:response, form: @form, answer_values: [['Plant', 'Oak']])
      @report = create(:answer_tally_report, option_sets: [@form.questions[0].option_set], run: true)
    end

    it 'should count only top-level answers' do
      expect(@report).to have_data_grid(
                                    %w(    Animal Plant TTL),
        [@form.questions[0].name] + %w(    3      1     4),
                                    %w(TTL 3      1     4)
      )
    end
  end

  describe 'results' do
    it "counts of yes and no for all yes no questions" do
      yes_no = create(:option_set, option_names: %w(Yes No))
      questions = (1..3).to_a.map{ |i| create(:question, qtype_name: 'select_one', option_set: yes_no, name: "Q#{i}", code: "q#{i}") }
      forms = create_list(:form, 2, questions: questions, option_set: yes_no)

      create_list(:response, 1, form: forms[0], answer_values: %w(Yes Yes Yes))
      create_list(:response, 2, form: forms[0], answer_values: %w(Yes Yes No))
      create_list(:response, 3, form: forms[0], answer_values: %w(Yes No Yes))
      create_list(:response, 4, form: forms[0], answer_values: %w(No Yes Yes))
      create_list(:response, 9, form: forms[1], answer_values: %w(No Yes))

      report = create_report("AnswerTally", option_set: yes_no)
      expect(report).to have_data_grid(%w(    Yes No TTL ),
                                       %w( q1   6 13  19 ),
                                       %w( q2  16  3  19 ),
                                       %w( q3   8  2  10 ),
                                       %w( TTL 30 18  48 ))

      # Try question_labels == 'title'
      report = create_report("AnswerTally", option_set: yes_no, question_labels: "title")

      expect(report).to have_data_grid(%w(    Yes No TTL ),
                                       %w( Q1   6 13  19 ),
                                       %w( Q2  16  3  19 ),
                                       %w( Q3   8  2  10 ),
                                       %w(TTL  30 18  48 ))

      # Try with joined-attrib filter
      report = create_report("AnswerTally", option_set: yes_no, filter: %Q{form: "#{forms[0].name}"})
      expect(report).to have_data_grid(%w(    Yes No TTL ),
                                       %w( q1   6  4  10 ),
                                       %w( q2   7  3  10 ),
                                       %w( q3   8  2  10 ),
                                       %w( TTL 21  9  30 ))
    end

    it "counts of options for specific questions across two option sets", :investigate do
      yes_no = create(:option_set, option_names: %w(Yes No))
      high_low = create(:option_set, option_names: %w(High Low))
      questions = []
      2.times{|i| questions << create(:question, code: "yn#{i}", qtype_name: "select_one", option_set: yes_no)}
      2.times{|i| questions << create(:question, code: "hl#{i}", qtype_name: "select_one", option_set: high_low)}
      form = create(:form, questions: questions)
      1.times{create(:response, form: form, answer_values: %w(Yes Yes High High))}
      2.times{create(:response, form: form, answer_values: %w(Yes Yes Low Low))}
      3.times{create(:response, form: form, answer_values: %w(Yes No Low High))}
      4.times{create(:response, form: form, answer_values: %w(No Yes High Low))}

      # Create report naming only three questions.
      report = create_report("AnswerTally",
        calculations: [0, 1, 3].map{ |i| Report::IdentityCalculation.new(question1: questions[i]) })


      # Attempted to fix flapping here by changing sort order slightly. See answer_tally_report.rb.
      expect(report).to have_data_grid(%w(     Yes No High Low TTL ),
                                       %w( yn0   6  4    _   _  10 ),
                                       %w( yn1   7  3    _   _  10 ),
                                       %w( hl1   _  _    4   6  10 ),
                                       %w( TTL  13  7    4   6  30 ))
    end

    it "counts of yes and no for empty result" do
      # Create several option sets but only responses for the last one.
      yes_no = create(:option_set, option_names: %w(Yes No))
      high_low = create(:option_set, option_names: %w(High Low))
      questions = [create(:question, code: "yn", qtype_name: "select_one", option_set: yes_no),
                   create(:question, code: "lh", qtype_name: "select_one", option_set: high_low)]
      form = create(:form, questions: [questions[1]])
      create_list(:response, 4, form: form, answer_values: %w(Low))

      report = create_report("AnswerTally", option_set: yes_no)

      expect(report).to have_data_grid(nil)
    end

    it "counts of options across a select one question and select multiple question", :investigate do
      # create several questions and responses for them
      yes_no = create(:option_set, option_names: %w(Yes No))
      rgb = create(:option_set, option_names: %w(Red Blue Green))
      questions = []
      questions << create(:question, code: "yn", qtype_name: "select_one", option_set: yes_no)
      questions << create(:question, code: "rgb", qtype_name: "select_multiple", option_set: rgb)
      form = create(:form, questions: questions)
      create_list(:response, 1, form: form, answer_values: ["Yes", %w(Red Blue)])
      create_list(:response, 2, form: form, answer_values: ["Yes", %w()])
      create_list(:response, 3, form: form, answer_values: ["Yes", %w(Green)])
      create_list(:response, 4, form: form, answer_values: ["No", %w(Red Blue Green)])

      report = create_report("AnswerTally", calculations: [
        Report::IdentityCalculation.new(question1: questions[0]),
        Report::IdentityCalculation.new(question1: questions[1])
      ])

      # Make sure we account for the null (no answer given) values that will come up for the rgb question (we use a _)
      expect(report).to have_data_grid(%w(      Yes No Red Blue Green _ TTL ),
                                       %w( yn     6  4   _    _     _ _  10 ),
                                       %w( rgb    _  _   5    5     7 2  19 ),
                                       %w( TTL    6  4   5    5     7 2  29 ))
    end
  end
end
