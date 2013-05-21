class FormsController < ApplicationController
  # special find method before load_resource
  before_filter :find_form_with_questions, :only => [:show, :edit, :update]
  
  # authorization via cancan
  load_and_authorize_resource

  # in the choose_questions action we have a question form so we need this Concern
  include QuestionFormable
  
  def index
    # handle different formats
    respond_to do |format|
      # render normally if html
      format.html do
        @forms = apply_filters(@forms).with_form_type.all
        render(:index)  
      end
      
      # get only published forms and render openrosa if xml requested
      format.xml do
        @forms = @forms.published.with_form_type
        render_openrosa
      end
    end
  end
  
  def new
    prepare_and_render_form
  end
  
  def edit
    prepare_and_render_form
  end
  
  def show
    # add to download count if xml
    @form.add_download if request.format && request.format.xml? 
    
    respond_to do |format|
      
      # for html, render the printable or sms_guide styles if requested, otherwise render the form
      format.html do 
        # printable style
        if params[:print]
          # here we only render a partial since this is coming from an ajax request
          render(:partial => "printable", :layout => false, :locals => {:form => @form})
          
        # sms guide style
        elsif params[:sms_guide]
          # determine the most appropriate language to show the form in
          # if params[:lang] is set, use that
          @lang = if params[:lang]
            params[:lang]
          # otherwise try to use the outgoing sms language (if available)
          elsif I18n.available_locales.include?((configatron.outgoing_sms_language || "en").to_sym)
            configatron.outgoing_sms_language.to_s
          # finally default to english
          else
            "en"
          end
          render("sms_guide")

        # otherwise just normal!
        else
          prepare_and_render_form
        end
      end
      
      # for xml, render openrosa
      format.xml{render_openrosa}
    end
  end
  
  def create
    if @form.update_attributes(params[:form])
      flash[:success] = "Form created successfully."
      redirect_to(edit_form_path(@form))
    else
      prepare_and_render_form
    end
  end
  
  def update
    begin
      # save basic attribs
      @form.assign_attributes(params[:form])
      
      # update ranks if provided (possibly raising condition ordering error)
      @form.update_ranks(params[:rank]) if params[:rank]

      # save everything and redirect
      @form.save!
      flash[:success] = "Form updated successfully."
      redirect_to(edit_form_path(@form))

    # handle problem with conditions
    rescue ConditionOrderingError
      @form.errors.add(:base, "The new rankings invalidate one or more conditions")
      prepare_and_render_form
    
    # handle other validation errors  
    rescue ActiveRecord::RecordInvalid
      prepare_and_render_form
    end
  end
  
  def destroy
    begin flash[:success] = @form.destroy && "Form deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  # publishes/unpublishes a form
  def publish
    verb = @form.published? ? "unpublish" : "publish"
    begin
      @form.send("#{verb}!")
      dl = verb == "unpublish" ? " The download count has also been reset." : ""
      flash[:success] = "Form #{verb}ed successfully." + dl
    rescue
      flash[:error] = "There was a problem #{verb}ing the form (#{$!.to_s})."
    end
    # redirect to form edit
    redirect_to(:action => :index)
  end
  
  # shows the form to either choose existing questions or create a new one to add
  def choose_questions
    @title = "Adding Questions to Form: #{@form.name}"
    
    # get questions for choice list
    @questions = Question.accessible_by(current_ability).not_in_form(@form)
    
    # setup new questioning for use with the questioning form
    init_qing(:form_id => @form.id, :question_attributes => {})
    setup_qing_form_support_objs
  end
  
  # adds questions selected in the big list to the form
  def add_questions
    # load the question objects
    questions = load_selected_objects(Question)

    # raise error if no valid questions (this should be impossible)
    raise "No valid questions given." if questions.empty?
    
    # add questions to form and try to save
    @form.questions += questions
    if @form.save
      flash[:success] = "Questions added successfully"
    else
      flash[:error] = "There was a problem adding the questions (#{@form.errors.full_messages.join(';')})"
    end
    
    # redirect to form edit
    redirect_to(edit_form_path(@form))
  end
  
  # removes selected questions from the form
  def remove_questions
    # get the selected questionings
    qings = load_selected_objects(Questioning)
    # destroy
    begin
      @form.destroy_questionings(qings)
      flash[:success] = "Questions removed successfully."
    rescue
      flash[:error] = "There was a problem removing the questions (#{$!.to_s})."
    end
    # redirect to form edit
    redirect_to(edit_form_path(@form))
  end
  
  # makes an unpublished copy of the form that can be edited without affecting the original
  def clone
    begin
      @form.duplicate
      flash[:success] = "Form '#{@form.name}' cloned successfully."
    rescue
      flash[:error] = "There was a problem cloning the form (#{$!.to_s})."
    end
    redirect_to(:action => :index)
  end
  
  private
    
    # adds the appropriate headers for openrosa content
    def render_openrosa
      render(:content_type => "text/xml")
      response.headers['X-OpenRosa-Version'] = "1.0"
    end
    
    # prepares objects and renders the form template
    def prepare_and_render_form
      # load the form types available to this user
      @form_types = FormType.accessible_by(current_ability)
      
      # render the form template
      render(:form)
    end
    
    # loads the form object including a bunch of joins for questions
    def find_form_with_questions
      @form = Form.with_questions.find(params[:id])
    end
end
