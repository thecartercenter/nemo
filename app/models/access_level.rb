class AccessLevel
  PRIVATE   = 1
  PUBLIC    = 2
  PROTECTED = 3

  def self.option_list(params = {})
    if params[:protected].present?
      {I18n.t('api_levels.level_2')  => PRIVATE,
       I18n.t('api_levels.level_3') => PROTECTED,
       I18n.t('api_levels.level_1') => PUBLIC}
    else
      {I18n.t('api_levels.level_2')  => PRIVATE,
       I18n.t('api_levels.level_1') => PUBLIC}
   end
  end
  
end
