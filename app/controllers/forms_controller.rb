class FormsController < ApplicationController
  # in the choose_questions action we have a question form so we need this
  include QuestionFormable  
  
  def index
    respond_to do |format|
      # render normally if html
      format.html do
        @forms = apply_filters(Form).with_form_type.all
        render(:index)
      end
      
      # get only published forms and render openrosa if xml requested
      format.xml do
        @forms = restrict(Form).published.with_form_type
        render_openrosa
      end
    end
  end
  
  def new
    @form = Form.for_mission(current_mission).new
    render_form
  end
  
  def edit
    @form = Form.with_questions.find(params[:id])
    render_form
  end
  
  def show
    @form = Form.with_questions.find(params[:id])

    # add to download count if xml
    @form.add_download if request.format.xml? 
    
    respond_to do |format|
      # for html, render the printable partial if requested, otherwise render the form
      format.html{params[:print] ? render_printable : render_form}
      
      # for xml, render openrosa
      format.xml{render_openrosa}
    end
  end
  
  def destroy
    @form = Form.find(params[:id])
    begin flash[:success] = @form.destroy && "Form deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  def publish
    @form = Form.find(params[:id])
    verb = @form.published? ? "unpublish" : "publish"
    
    # if form is being published, need to create its sms code
    if verb == 'publish'
    # TOM please replace all tab characters with '  ', (two spaces)
    	create_sms_code
    end
    
    begin
      @form.toggle_published
      dl = verb == "unpublish" ? " The download count has also been reset." : ""
      flash[:success] = "Form #{verb}ed successfully." + dl
    rescue
      flash[:error] = "There was a problem #{verb}ing the form (#{$!.to_s})."
    end
    # redirect to form edit
    redirect_to(:action => :index)
  end
  
  # GET /forms/:id/choose_questions
  # show the form to either choose existing questions or create a new one to add
  def choose_questions
    @form = Form.find(params[:id])
    @title = "Adding Questions to Form: #{@form.name}"
    
    # get questions for choice list
    @questions = apply_filters(Question.not_in_form(@form))
    
    # setup new questioning for use with the questioning form
    @qing = init_qing(:form_id => @form.id)
    setup_qing_form_support_objs
  end
  
  def add_questions
    # load the form
    @form = Form.find(params[:id])
    
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
  
  
  def remove_questions
    # load the form
    @form = Form.find(params[:id])
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
  
  def update_ranks
    redirect_to(edit_form_path(@form))
  end
  
  def clone
    @form = Form.find(params[:id])
    begin
      @form.duplicate
      flash[:success] = "Form '#{@form.name}' cloned successfully."
    rescue
      raise $!
      flash[:error] = "There was a problem cloning the form (#{$!.to_s})."
    end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  
  def update; crupdate; end
  
  private
  
    def crupdate
      action = params[:action]
      @form = action == "create" ? Form.for_mission(current_mission).new : Form.find(params[:id], :include => {:questionings => :condition})
      
      begin
        # save basic attribs
        @form.attributes = params[:form]
        
        # update ranks if provided
        if params[:rank]
          # build hash of questioning ids to ranks
          new_ranks = {}; params[:rank].each_pair{|id, rank| new_ranks[id] = rank}
          
          # update (possibly raising condition ordering error)
          @form.update_ranks(new_ranks)
        end
        
        # save everything and redirect
        @form.save!
        flash[:success] = "Form #{action}d successfully."
        redirect_to(edit_form_path(@form))

      # handle problem with conditions
      rescue ConditionOrderingError
        @form.errors.add(:base, "The new rankings invalidate one or more conditions")
        render_form
      
      # handle other validation errors  
      rescue ActiveRecord::RecordInvalid
        render_form
      end
    end
    
    # adds the appropriate headers for openrosa content
    def render_openrosa
      render(:content_type => "text/xml")
      response.headers['X-OpenRosa-Version'] = "1.0"
    end
    
    # renders the printable partial
    def render_printable
      render(:partial => "printable", :layout => false, :locals => {:form => @form})
    end
    
    def render_form
      @form_types = apply_filters(FormType)
      render(:form)
    end
    
    # TOM this seems like model code to me
    def create_sms_code	
		# clears sms_codes of old data for form_id
		SmsCode.delete_all(:form_id => @form.id)				
		
		# only prints qings that are not hidden, not conditional, and are of the type (select_one, select_multiple or integer)
		qings = @form.questionings.select { |q| q.hidden == false && q.condition == nil && (q.question.type.name == 'select_one' || q.question.type.name == 'select_multiple' || q.question.type.name == 'integer')}	   
		
		qings.each_with_index do |qing, n|
			# not a zero based index for question numbers!
			nn = n + 1	
			SmsCode.load_sms_code(qing, nn)	
		end
	end
    
end
