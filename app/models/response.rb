require 'xml'
class Response < ActiveRecord::Base
  include MissionBased

  belongs_to(:form, :inverse_of => :responses, :counter_cache => true)
  has_many(:answers, :include => :questioning, :order => "questionings.rank", 
    :autosave => true, :validate => false, :dependent => :destroy, :inverse_of => :response)
  belongs_to(:user, :inverse_of => :responses)
  
  attr_accessor(:modifier)
  
  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates(:user, :presence => true)
  validate(:no_missing_answers)

  # don't need to validate answers in odk mode
  validates_associated(:answers, :message => :invalid_answers, :if => Proc.new{|r| r.modifier != "odk"})
  
  default_scope(includes(:form, :user).order("responses.created_at DESC"))
  scope(:unreviewed, where(:reviewed => false))
  scope(:by, lambda{|user| where(:user_id => user.id)})
  
  # loads all the associations required for show, edit, etc.
  scope(:with_associations, includes(
    :form, {
      :answers => [
        {:choices => :option},
        :option, 
        {:questioning => [:condition, {:question => {:option_set => :options}}]}
      ]
    }
  ))
  
  self.per_page = 20
  
  # takes a Relation, adds a bunch of selects and joins, and uses find_by_sql to do the actual finding
  # this technique is due to limitations (at the time of dev) in the Relation system
  def self.for_export(rel)
    find_by_sql(export_sql(rel))
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_qualifiers
    [
      Search::Qualifier.new(:name => "form", :col => "forms.name", :assoc => :forms),
      Search::Qualifier.new(:name => "reviewed", :col => "responses.reviewed"),
      Search::Qualifier.new(:name => "submitter", :col => "users.name", :assoc => :users, :partials => true),
      Search::Qualifier.new(:name => "source", :col => "responses.source"),
      Search::Qualifier.new(:name => "date", :col => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '#{Time.zone.mysql_name}'))"),

      # this qualifier matches responses that have answers to questions with the given option set
      Search::Qualifier.new(:name => "option_set", :col => "option_sets.name", :assoc => :option_sets),

      # this qualifier matces responses that have answers to questions with the given type
      Search::Qualifier.new(:name => "question_type", :col => "questions.qtype_name", :assoc => :questions),

      # this qualifier matces responses that have answers to the given question
      Search::Qualifier.new(:name => "question", :col => "questions.code", :assoc => :questions)
    ]
  end
  
  def self.search_examples
    ["#{I18n.t('search_qualifiers.submitter')}:\"john smith\"", 
      "#{I18n.t('search_qualifiers.form')}:polling", 
      "#{I18n.t('search_qualifiers.reviewed')}:1", 
      "#{I18n.t('search_qualifiers.date')} < 2010-03-15"]
  end

  # returns a count how many responses have arrived recently
  # format e.g. [5, "week"] (5 in the last week)
  # nil means no recent responses
  def self.recent_count(rel)
    %w(hour day week month).each do |p|
      if (count = rel.where("created_at > ?", 1.send(p).ago).count) > 0
        return [count, p]
      end
    end
    nil
  end
  
  def populate_from_xml(xml)
    # parse xml
    doc = XML::Parser.string(xml).parse
    
    # set the source/modifier values to odk
    self.source = self.modifier = "odk"

    # get form id
    if doc.root["id"]
      self.form_id = doc.root["id"].to_i
    else
      raise ArgumentError.new("no form id was given")
    end
    
    # check if the form is associated with this response's mission
    unless mission && form = Form.for_mission(mission).find_by_id(form_id)
      raise ArgumentError.new("form not found")
    end
    
    # get the visible questionings
    qings = form.visible_questionings
    
    # loop over each child tag and create hash of question_code => value
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}
    
    # loop over all the questions in the form and create answers
    qings.each do |qing|
      # get value from hash
      str = values[qing.question.odk_code]
      # add answer
      self.answers << Answer.new_from_str(:str => str, :questioning => qing)
    end
  end
  
  def visible_questionings
    # get visible questionings from form
    form.visible_questionings
  end
  
  def all_answers
    # make sure there is an associated answer object for each questioning in the form
    visible_questionings.collect{|qing| answer_for(qing) || answers.new(:questioning => qing)}
  end
  
  def all_answers=(params)
    # do a match on current and newer ids with the ID as the comparator
    answers.compare_by_element(params.values, Proc.new{|a| a[:questioning_id].to_i}) do |orig, subd|
      # if both exist, update the original
      if orig && subd
        orig.attributes = subd
      # if submitted is nil, destroy the original
      elsif subd.nil?
        answers.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        answers << Answer.new(subd)
      end
    end
  end

  def answer_for(questioning)
    # get the matching answer(s)
    answer_for_qing[questioning]
  end
  
  def answer_for_qing(options = {})
    @answer_for_qing = nil if options[:rebuild]
    @answer_for_qing ||= answers.index_by(&:questioning)
  end
  
  def answer_for_question(question)
    (@answers_by_question ||= answers.index_by(&:question))[question]
  end
  
  # returns an array of required questionings for which answers are missing
  def missing_answers
    return @missing_answers if @missing_answers
    answer_for_qing(:rebuild => true)
    @missing_answers = visible_questionings.collect do |qing|
      (answer_for(qing).nil? && qing.required?) ? qing : nil
    end.compact
  end
  
  def form_name; form ? form.name : nil; end
  def submitter; user ? user.name : nil; end
  
  private
    def no_missing_answers
      errors.add(:base, :missing_answers) unless missing_answers.empty?
    end
    
    def self.export_sql(rel)
      # add all the selects
      # assumes the language desired is English. currently does not respect the locale
      rel = rel.select("responses.id AS response_id")
      rel = rel.select("responses.created_at AS submission_time")
      rel = rel.select("responses.reviewed AS is_reviewed")
      rel = rel.select("forms.name AS form_name")
      rel = rel.select("questions.code AS question_code")
      rel = rel.select("questions._name AS question_name")
      rel = rel.select("questions.qtype_name AS question_type")
      rel = rel.select("users.name AS submitter_name")
      rel = rel.select("answers.id AS answer_id")
      rel = rel.select("answers.value AS answer_value")
      rel = rel.select("answers.datetime_value AS answer_datetime_value")
      rel = rel.select("answers.date_value AS answer_date_value")
      rel = rel.select("answers.time_value AS answer_time_value")
      rel = rel.select("IFNULL(ao._name, co._name) AS choice_name")
      rel = rel.select("option_sets.name AS option_set")

      # add all the joins
      rel = rel.joins(Report::Join.list_to_sql([:users, :forms, 
        :answers, :questionings, :questions, :option_sets, :options, :choices]))
        
      rel.to_sql
    end
end
