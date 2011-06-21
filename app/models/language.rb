class Language < ActiveRecord::Base
  before_validation(:clean_fields)
  validates(:name, :presence => true, :uniqueness => true)
  validate(:english_mandatory)
  before_destroy(:check_assoc_and_english_mandatory)
  
  def self.sorted(params = {})
    func = params.delete(:paginate) ? "paginate" : "find"
    send(func, :all, params.merge(:order => "name"))
  end
  def self.select_options
    sorted.collect{|l| [l.name, l.id]}
  end
  def self.default
    new(:is_active => true)
  end
  def self.english
    @@english ||= find_by_name("English")
  end
  
  private
    def english_mandatory
      # English must always be active
      if self == self.class.english && !is_active
        errors.add(:is_active, "can't be false since English must always be active")
      end
    end
    def check_assoc_and_english_mandatory
      # Can't delete English
      if self == self.class.english
        raise("You can't delete #{name}.") 
      # Can't delete languages with related translations.
      elsif false # Translation.find_by_language_id(id)
        raise("You can't delete #{name} because it has assocaited translations. Try deactivating it.")
      end
    end
    def clean_fields
      self.name.gsub!(/\b\w/){$&.upcase}
    end
end
