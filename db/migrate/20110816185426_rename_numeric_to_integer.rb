class RenameNumericToInteger < ActiveRecord::Migration[4.2]
  def self.up
    execute("update question_types set name = 'integer', long_name = 'Integer' where name = 'numeric'")
    # this is now obsolete
    #QuestionType.create(:name => "decimal", :long_name => "Decimal", :odk_name => "decimal", :odk_tag => "input")
  end

  def self.down
  end
end
