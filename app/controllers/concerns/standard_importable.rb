# frozen_string_literal: true

# methods required to setup a question for use in the new question form
module StandardImportable
  extend ActiveSupport::Concern

  # controller action to import standard objs
  # expects params[:objs_to_import], an array of IDs of objects to import
  # attempts to import each, failing silently if any import fails and continuing on to next
  # imports generally shouldn't fail, however
  def import_standard
    # for each id, try to find the object and import it. keep a count. if there are errors,
    # just log them to debug, since this should never happen.
    import_count = 0
    error_count = 0
    params[:objs_to_import].each do |id|
      obj = model_class.find(id)
      obj.replicate(mode: :to_mission, dest_mission: current_mission)
      import_count += 1
    rescue StandardError
      error_count += 1
      logger.debug("ERROR #{$ERROR_INFO} IMPORTING #{model_class.try(:name)} ##{id} " \
        "TO MISSION #{current_mission.try(:name)}")
      logger.debug($ERROR_INFO.backtrace.to_a.join("\n"))
    end

    flash_key = params[:objs_to_import].size == error_count ? :error : :success

    # set the flash message
    flash[flash_key] = I18n.t("standard.import_success.#{controller_name}", count: import_count)
    if error_count.positive?
      flash[flash_key] += " (#{I18n.t('standard.there_were_errors', count: error_count)})"
    end

    redirect_to(action: :index)
  end

  private

  # gets the set of std objs that can be imported to the current mission and sets them in an instance var
  def load_importable_objs
    return if admin_mode? || !can?(:create, model_class)
    @importable = model_class.importable_to(current_mission).default_order
  end
end
