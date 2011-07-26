class Language < ActiveRecord::Base
  require 'language_list'
  validates(:code, :presence => true, :uniqueness => true)
  validate(:english_mandatory)
  before_destroy(:check_assoc_and_english_mandatory)
  after_save(:rebuild_hash)
  
  def self.sorted(params = {})
    func = params.delete(:paginate) ? "paginate" : "find"
    send(func, :all, params.merge(:order => "code = 'eng' desc, code"))
  end
  def self.by_code(code)
    code_hash[code]
  end
  def self.code_hash(options = {})
    if !defined?(@@code_hash) || options[:rebuild]
      @@code_hash = Hash[*all.collect{|l| [l.code, l]}.flatten]
    end
    @@code_hash
  end
  def self.active
    sorted(:conditions => "is_active = 1")
  end
  def self.select_options
    sorted.collect{|l| [l.name, l.id]}
  end
  def self.add_select_options
    LanguageList::LANGS.map{|code, name| [name, code]}.sort_by{|pair| pair[0]}
  end
  def self.default
    new(:is_active => true)
  end
  def self.english
    @@english ||= find_by_code("eng")
  end
  def is_english?
    code == "eng"
  end
  def name
    LanguageList::LANGS[code.to_sym]
  end
  
  private
    def english_mandatory
      if code_was == "eng"
        errors.add(:base, "You can't change English because it's the main system language.")
      end
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
      elsif Translation.find_by_language_id(id)
        raise("You can't delete #{name} because it has associated translations. Try deactivating it.")
      end
    end
    def rebuild_hash
      self.class.code_hash(:rebuild => true)
    end
end
