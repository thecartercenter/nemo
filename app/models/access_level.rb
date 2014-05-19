class AccessLevel
  PRIVATE   = 1
  PUBLIC    = 2
  PROTECTED = 3

  def self.option_list(params = {})
    levels = {I18n.t('api_levels.level_2')  => PUBLIC, I18n.t('api_levels.level_1') => PRIVATE}
    # Right now only forms have option to have protected as access level
    levels.merge!({I18n.t('api_levels.level_3') => PROTECTED}) if params[:protected].present?
    levels
  end
  
end
