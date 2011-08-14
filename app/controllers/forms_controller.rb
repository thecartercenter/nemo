class FormsController < ApplicationController
  def index
    if request.format.xml?
      @forms = Form.sorted(:conditions => "forms.is_published = 1", :include => [:type])
    else
      @subindex = Subindex.find_and_update(session, current_user, "Form", params[:page])
      @forms = Form.sorted(@subindex.params)
    end
    render_appropriate_format
  end
  def new
    @form = Form.new
    render_and_setup("create")
  end
  def edit
    @form = Form.find(params[:id])
    render_and_setup("update")
  end
  def show
    @form = Form.find_eager(params[:id])
    @form.add_download if request.format.xml? 
    render_appropriate_format
  end
  def destroy
    @form = Form.find(params[:id])
    begin flash[:success] = @form.destroy && "Form deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  def publish
    @form = Form.find(params[:id])
    verb = @form.is_published? ? "unpublish" : "publish"
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
    @form = Form.find(params[:id])
    begin
      # build hash of Questionings to ranks
      new_ranks = {}; params[:rank].each_pair{|id, rank| new_ranks[Questioning.find(id)] = rank}
      # update
      @form.update_ranks(new_ranks)
      flash[:success] = "Ranks updated successfully."
    rescue
      flash[:error] = "There was a problem updating the ranks (#{$!.to_s})."
    end
    redirect_to(edit_form_path(@form))
  end
  def clone
    @form = Form.find(params[:id])
    begin
      @form.clone
      flash[:success] = "Form '#{@form.name}' cloned successfully."
    rescue
      flash[:error] = "There was a problem cloning the form (#{$!.to_s})."
    end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end
  private
    def crupdate
      action = params[:action]
      @form = action == "create" ? Form.new : Form.find(params[:id])
      begin
        @form.update_attributes!(params[:form])
        flash[:success] = "Form #{action}d successfully."
        redirect_to(edit_form_path(@form))
      rescue ActiveRecord::RecordInvalid
        render_and_setup(action)
      end
    end
    def render_appropriate_format
      respond_to do |format|
        format.html
        format.xml do
          render(:content_type => "text/xml")
          response.headers['X-OpenRosa-Version'] = "1.0"
        end
      end
    end
    def render_and_setup(action)
      @title = action == "create" ? "Create Form" : "Edit Form: #{@form.name}"
      render(:action => action == "create" ? :new : :edit)
    end
end
