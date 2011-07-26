class QuestionType < ActiveRecord::Base
  def self.select_options
    all(:order => "long_name").collect{|qt| [qt.long_name, qt.id]}
  end
end
