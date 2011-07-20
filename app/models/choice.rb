class Choice < ActiveRecord::Base
  belongs_to(:answer)
  belongs_to(:option)
  
  def option_name; option.name; end
  def checked; @checked; end
  def checked=(v); @checked = v; end
end
