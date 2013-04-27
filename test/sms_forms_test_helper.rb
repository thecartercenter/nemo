ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

# methods for testing sms forms functionality
class ActiveSupport::TestCase

  # helper that sets up a new form with the given parameters
  def setup_form(options)
    # default question required option
    options[:required] ||= false
    
    @form = FactoryGirl.create(:form, :smsable => true)
    options[:questions].each do |type|
      # create the question
      q = FactoryGirl.build(:question, :question_type_id => QuestionType.find_by_name(type).id)
    
      # add an option set if required
      if %w(select_one select_multiple).include?(type)
        q.option_set = FactoryGirl.create(:option_set, :name => "Options", :option_names => %w(A B C D E))
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