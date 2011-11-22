class FormType < ActiveRecord::Base
  has_many(:forms)
  
  def self.select_options
    all(:order => "name").collect{|ft| [ft.name, ft.id]}
  end
end
