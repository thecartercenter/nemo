# methods required to setup a question for use in the new question form
module StandardImportable
  extend ActiveSupport::Concern

  # controller action to import standard objs
  # expects params[:objs_to_import], an array of IDs of objects to import
  # attempts to import each, failing silently if any import fails and continuing on to next
  # imports generally shouldn't fail, however
  def import_standard
    redirect_to(:action => :index)
  end

  private
    # gets the set of std objs that can be imported to the current mission and sets them in an instance var
    def get_importable_objs
      klass = controller_name.classify.constantize
      @importable = klass.importable_to(current_mission) if !admin_mode? && can?(:manage, klass)
    end
end