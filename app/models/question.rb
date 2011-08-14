require 'translatable'

class Question < ActiveRecord::Base
  include Translatable
  
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set, :include => :options)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "class_name='Question'", :autosave => true, :dependent => :destroy)
  has_many(:questionings)
  has_many(:answers, :through => :questionings)
  has_many(:forms, :through => :questionings)

  validates(:code, :presence => true, :uniqueness => true)
  validates(:code, :format => {:with => /^[a-z][a-z0-9]{1,15}$/}, :if => Proc.new{|q| !q.code.blank?})
  validates(:type, :presence => true)
  validates(:option_set_id, :presence => true, :if => Proc.new{|q| q.is_select?})
  validates(:english_name, :presence => true)
  validate(:integrity)
    
  before_validation(:clean)
  before_destroy(:check_assoc)
  
  # returns questions that do NOT already appear in the given form
  def self.not_in_form(form, params)
    # add the condition
    params[:conditions] = "(#{params[:conditions] || 1}) and " + 
      "(questions.id not in (select question_id from questionings where form_id='#{form.id}'))"
    # pass along to sorted method
    sorted(params)
  end
  
  def self.sorted(params = {})
    paginate(:all, params.merge(:order => "code"))
  end
  
  def self.per_page; 100; end
  
  def self.default_eager; [:type, :translations, :questionings, :answers, :forms]; end
  
  def method_missing(*args)
    # enable methods like name_fra and hint_eng, etc.
    if args[0].match(/^(name|hint)_([a-z]{3})(_before_type_cast)?(=?)$/)
      send("#{$1}#{$4}", Language.by_code($2), *args[1..2])
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private)
    is_translation_method?(symbol) || super
  end
  
  def is_translation_method?(symbol)
    symbol.match(/^(name|hint)_([a-z]{3})(_before_type_cast)?(=?)$/)
  end
  
  # hack so the validation message will look right
  def english_name; name_eng; end
  
  def name(lang = nil); translation_for(:name, lang); end
  def name=(lang = nil, value); set_translation_for(:name, lang, value); end
  def hint(lang = nil); translation_for(:hint, lang); end
  def hint=(lang = nil, value); set_translation_for(:hint, lang, value); end

  def options
    option_set ? option_set.options : nil
  end
  def is_select?
    type && type.name.match(/^select/)
  end
  def select_options
    (opt = options) ? opt.collect{|o| [o.name, o.id]} : []
  end
  def is_location?
    type.name == "location"
  end
  def is_address?
    type.name == "address"
  end
  def published?
    !forms.detect{|f| f.is_published?}.nil?
  end
  
  private
    def clean
      self.code.downcase! if code
    end
    def integrity
      # error if type or option set have changed and there are answers
      if (question_type_id_changed? || option_set_id_changed?) && !answers.empty?
        errors.add(:base, "Type or option set can't be changed because there are already responses for this question")
      end
      # error if anything has changed and the question is published
      if published? && (changed? || translations.detect{|t| t.changed?})
        errors.add(:base, "Can't be changed because it appears in at least one published form")
      end
    end
    def check_assoc
      unless questionings.empty?
        raise("You can't delete question '#{code}' because it is included in at least one form")
      end
    end
end
