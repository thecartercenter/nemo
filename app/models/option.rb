require 'translatable'

class Option < ActiveRecord::Base
  include Translatable
  
  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "class_name='Option'", :autosave => true, :dependent => :destroy)
  has_many(:answers)
  has_many(:choices)
  
  validates(:value, :presence => true)
  validates(:value, :numericality => true, :if => Proc.new{|o| !o.value.blank?})
  validates(:english_name, :presence => true)
  validate(:integrity)
  validate(:name_lengths)
  
  before_destroy(:check_assoc)
  
  def self.sorted(params = {})
    paginate(:all, params)
  end

  def self.per_page; 100; end

  def self.default_eager; [:translations, {:option_sets => [:questionings, {:questions => {:questionings => :form}}]}]; end

  def method_missing(*args)
    # enable methods like name_fra and hint_eng, etc.
    if args[0].match(/^(name)_([a-z]{3})(_before_type_cast)?(=?)$/)
      send("#{$1}#{$4}", Language.by_code($2), *args[1..2])
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private)
    is_translation_method?(symbol) || super
  end
  
  def is_translation_method?(symbol)
    symbol.match(/^(name)_([a-z]{3})(_before_type_cast)?(=?)$/)
  end
  
  # hack so the validation message will look right
  def english_name; name_eng; end
  
  def name(lang = nil); translation_for(:name, lang); end
  def name=(lang, value); set_translation_for(:name, lang, value); end
  
  def published?; !option_sets.detect{|os| os.published?}.nil?; end
  
  def questions; option_sets.collect{|os| os.questions}.flatten.uniq; end

  private
    def integrity
      # error if anything has changed and the option is published
      if published? && (changed? || translations.detect{|t| t.changed?})
        errors.add(:base, "Option can't be changed because it appears in at least one published form")
      end
    end
    def check_assoc
      # could be in a published form but no responses yet
      if published?
        raise("You can't delete option '#{name_eng}' because it is included in at least one published form")
      end
      unless answers.empty? && choices.empty?
        raise("You can't delete option '#{name_eng}' because it is included in at least one response")
      end
    end
    def name_lengths
      if translations.detect{|t| t.str && t.str.size > 30}
        errors.add(:base, "Names must be at most 30 characters in length")
      end
    end
end
