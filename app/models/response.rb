require 'mission_based'
require 'xml'
class Response < ActiveRecord::Base
  include MissionBased

  belongs_to(:form, :inverse_of => :responses, :counter_cache => true)
  has_many(:answers, :include => :questioning, :order => "questionings.rank", 
    :autosave => true, :validate => false, :dependent => :destroy, :inverse_of => :response)
  belongs_to(:user, :inverse_of => :responses)
  
  # before_save hashAnswers and set Response.hash to the hash
  before_save :hash_answers
  
  attr_accessor(:modifier)
  
  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates(:user, :presence => true)
  validate(:no_missing_answers)

  # only need to validate answers in web mode
  validates_associated(:answers, :message => "are invalid (see below)", :if => Proc.new{|r| r.modifier == "web"})
  
  default_scope(includes({:form => :type}, :user).order("responses.created_at DESC"))
  scope(:unreviewed, where(:reviewed => false))
  scope(:by, lambda{|user| where(:user_id => user.id)})
  
  self.per_page = 20
  
  def self.find_eager(id)
    includes([:form, {:answers => 
      {
        :choices => {:option => :translations},
        :option => :translations, 
        :questioning => [:condition, {:question => [:type, :translations, {:option_set => {:options => :translations}}]}]
      }
    }]).find(id)
  end
  
  def self.for_export(rel)
    find_by_sql(export_sql(rel))
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_qualifiers
    [
      Search::Qualifier.new(:label => "form", :col => "forms.name", :assoc => :forms),
      Search::Qualifier.new(:label => "form-type", :col => "form_types.name", :assoc => :form_types),
      Search::Qualifier.new(:label => "reviewed", :col => "responses.reviewed", :subst => {"yes" => "1", "no" => "0"}),
      Search::Qualifier.new(:label => "signature", :col => "responses.signature"),
      Search::Qualifier.new(:label => "submitter", :col => "users.name", :assoc => :users, :partials => true),
      Search::Qualifier.new(:label => "source", :col => "responses.source"),
      Search::Qualifier.new(:label => "date", :col => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '#{Time.zone.mysql_name}'))"),

      # this qualifier matches responses that have answers to questions with the given option set
      Search::Qualifier.new(:label => "option-set", :col => "option_sets.name", :assoc => :option_sets),

      # this qualifier matces responses that have answers to questions with the given type
      Search::Qualifier.new(:label => "question-type", :col => "question_types.long_name", :assoc => :question_types),

      # this qualifier matces responses that have answers to the given question
      Search::Qualifier.new(:label => "question", :col => "questions.code", :assoc => :questions)
    ]
  end
  
  def self.search_examples
    ['submitter:"john smith"', 'form:polling', 'reviewed:yes', 'date < 2010-03-15']
  end

  def self.create_from_xml(xml, user, mission)
    # parse xml
    doc = XML::Parser.string(xml).parse

    # get form id
    form_id = doc.root["id"] or raise ArgumentError.new("No form id was given.")
    
    # check if the form is associated with the mission
    unless mission && form = Form.for_mission(mission).find_by_id(form_id)
      raise ArgumentError.new("Could not find the specified form.")
    end
    
    # create response object
    resp = new(:form => form, :user => user, :mission => mission, :source => "odk", :modifier => "odk")
    
    # get the visible questionings
    qings = resp.form.visible_questionings
    
    # loop over each child tag and create hash of question_code => value
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}
    
    # loop over all the questions in the form and create answers
    qings.each do |qing|
      # get value from hash
      str = values[qing.question.odk_code]
      # add answer
      resp.answers << Answer.new_from_str(:str => str, :questioning => qing)
    end

    # save the works
    resp.save!
  end
  
  # finds all responses with duplicate hashes
  def self.find_duplicates(signature)
    possible_duplicates = self.where("signature = '" + signature + "' AND id != " + self.id.to_s + " ")
    return possible_duplicates
  end
  
  # hashes all the answer values of the response
  def hash_answers
    answers = self.all_answers
    answers_digest = ""
    answers.each do |a|
      answer_value = a.value || a.option_id || a.time_value || a.date_value || a.datetime_value
      answers_digest = answers_digest + answer_value.to_s
    end
    signature = Digest::SHA1.hexdigest(answers_digest)
    self.signature = signature
    puts("signature hashed as " + self.signature)
  end
  
  # returns a human-readable description of how many responses have arrived recently
  def self.recent_count(rel)
    %w(hour day week month).each do |p|
      if (x = rel.where("created_at > ?", 1.send(p).ago).count) > 0 
        return "#{x} in the Past #{p.capitalize}"
      end
    end
    "No recent responses"
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
    answer_hash[questioning]
  end
  
  def answer_hash(options = {})
    @answer_hash = nil if options[:rebuild]
    @answer_hash ||= Hash[*answers.collect{|a| [a.questioning, a]}.flatten]
  end
  
  def form_name; form ? form.name : nil; end
  def submitter; user ? user.name : nil; end
  
  private
    def no_missing_answers
      answer_hash(:rebuild => true)
      visible_questionings.each do |qing|
        errors.add(:base, "Not all questions have answers") and return false if answer_for(qing).nil?
      end
    end
    
    def self.export_sql(rel)
      # add all the selects
      rel = rel.select("responses.id AS response_id")
      rel = rel.select("responses.created_at AS submission_time")
      rel = rel.select("responses.reviewed AS is_reviewed")
      rel = rel.select("forms.name AS form_name")
      rel = rel.select("form_types.name AS form_type")
      rel = rel.select("questions.code AS question_code")
      rel = rel.select("question_trans.str AS question_name")
      rel = rel.select("question_types.name AS question_type")
      rel = rel.select("users.name AS submitter_name")
      rel = rel.select("answers.id AS answer_id")
      rel = rel.select("answers.value AS answer_value")
      rel = rel.select("answers.datetime_value AS answer_datetime_value")
      rel = rel.select("answers.date_value AS answer_date_value")
      rel = rel.select("answers.time_value AS answer_time_value")
      rel = rel.select("IFNULL(aotr.str, cotr.str) AS choice_name")
      rel = rel.select("IFNULL(ao.value, co.value) AS choice_value")
      rel = rel.select("option_sets.name AS option_set")

      # add all the joins
      rel = rel.joins(Report::Join.list_to_sql([:users, :forms, :form_types, 
        :answers, :questionings, :questions, :question_types, :question_trans, :option_sets, :options, :choices]))
        
      rel.to_sql
    end
end
