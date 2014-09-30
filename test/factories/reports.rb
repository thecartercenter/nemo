FactoryGirl.define do
  factory :report, :class => 'Report::Report' do
    mission { get_mission }
    sequence(:name) { |n| "Report #{n}" }

    factory :gridable_report do
      ignore do
        # This should be a list of either strings (for attrib names) or questions.
        _calculations []
      end

      calculations_attributes do
        _calculations.each_with_index.map do |c,i|
          {rank: i + 1, type: "Report::IdentityCalculation"}.tap do |attribs|
            attribs[:attrib1_name] = c if c.is_a?(String)
            attribs[:question1] = c if c.is_a?(Question)
          end
        end
      end

      factory :answer_tally_report, class: 'Report::AnswerTallyReport' do
      end

      factory :response_tally_report, class: 'Report::ResponseTallyReport' do
      end

      factory :list_report, class: 'Report::ListReport' do
      end
    end

    factory :standard_form_report, class: 'Report::StandardFormReport' do
      form
    end
  end
end