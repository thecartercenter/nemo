class AccessLevel
  PRIVATE   = 1
  PUBLIC    = 2
  PROTECTED = 3

  def self.option_list(params)
    levels = {'Public'  => PUBLIC, 'Private' => PRIVATE}
    # Right now only forms have option to have protected as access level
    levels.merge!({'Protected' => PROTECTED}) if params[:protected].present?
    levels
  end
  
end
