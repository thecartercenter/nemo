ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

# methods for testing sms forms functionality
class ActiveSupport::TestCase

  # helper that sets up a new form with the given parameters
  def setup_form(options)
    # default question required option
    options[:required] ||= false
    options[:mission] ||= get_mission
    
    @form = FactoryGirl.create(:form, :smsable => true, :mission => options[:mission])
    options[:questions].each do |type|
      # create the question
      q = FactoryGirl.build(:question, :question_type_id => QuestionType.find_by_name(type).id, :mission => options[:mission])
      
      # add an option set if required
      if %w(select_one select_multiple).include?(type)
        # put options in weird order to ensure the order stuff works ok
        q.option_set = FactoryGirl.create(:option_set, :name => "Options", :option_names => %w(A B C D E), :mission => options[:mission])
      end
      
      q.save!
      
      # add it to the form
      @form.questionings.create(:question => q, :required => options[:required])
    end
    @form.publish!
    @form.reload
  end

  # gets the version code for the current form
  def form_code
    @form.current_version.code
  end
  
end