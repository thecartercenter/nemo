class Choice < ActiveRecord::Base
  belongs_to(:answer, :inverse_of => :choices, :touch => true)
  belongs_to(:option, :inverse_of => :choices)

  def option_name; option.name; end
  def checked; @checked; end
  def checked=(v); @checked = v; end
end
