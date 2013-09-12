# methods required to setup a question for use in the new question form
module StandardImportable
  extend ActiveSupport::Concern


  private
    # gets the set of std objs that can be imported to the current mission and sets them in an instance var
    def get_importable_objs
      klass = controller_name.classify.constantize
      @importable = klass.importable_to(current_mission) if !admin_mode? && can?(:manage, klass)
    end
end