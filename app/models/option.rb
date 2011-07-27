require 'translatable'

class Option < ActiveRecord::Base
  include Translatable
  
  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "class_name='Option'")
  
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
  def name=(lang = nil, value); set_translation_for(:name, lang, value); end
  
  def published?; !option_sets.detect{|os| os.published?}.nil?; end
end
