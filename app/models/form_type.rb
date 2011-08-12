class FormType < ActiveRecord::Base
  def self.select_options
    all(:order => "name").collect{|ft| [ft.name, ft.id]}
  end
end
