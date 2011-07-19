require 'xml'

class Response < ActiveRecord::Base
  belongs_to(:form)
  has_many(:answers)
  belongs_to(:place)
  has_many(:reviews)
  belongs_to(:user)

  validates(:user, :presence => true)
  validates(:observed_at, :presence => true)
  validate(:required_answers)
  
  def self.sorted(params = {})
    params.merge!(:order => "responses.created_at desc")
    paginate(:all, params)
  end
  
  def self.default_eager
    [:reviews, {:form => :type}, :user, :place]
  end
  
  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_fields
    {:formname => {:colname => "forms.name", :default => false, :regexp => true},
     :formtype => {:colname => "form_types.name", :default => false, :regexp => false},
     :place => {:colname => "places.full_name", :default => false, :regexp => true},
     :submitter => {:colname => "concat(users.first_name, ' ', users.last_name)", :default => false, :regexp => true},
     :answer => {:colname => "answers.value", :default => true, :regexp => true, :eager => [:answers]}}
  end
  
  # gets the lhs, operator, and rhs of a query fragment with the given field and term
  def self.query_fragment(field, term)
    [search_fields[field][:colname], "like", "%#{term}%"]
  end
  
  def self.search_examples
    ['submitter:"john smith"', 'formname:polling', 'formtype:sto', 'place:beirut']
  end

  def self.create_from_xml(xml, user)
    # parse xml
    doc = XML::Parser.string(xml).parse

    # get form id
    form_id = doc.root["id"] or raise ArgumentError.new("No form id.")
    form_id = form_id.to_i
    
    # create response object
    resp = new(:form_id => form_id, :user_id => user ? user.id : nil)
    qs = begin resp.form.questions rescue raise ArgumentError.new("Invalid form id.") end
    
    # loop over each child tag and create hash of values
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}
    
    # loop over all the questions in the form and create answers
    # if we find a location question, set the response location
    # if we find a start_timestamp question, save it also
    place_bits = {}
    start_time = nil
    qs.each do |q|
      # get value from hash
      v = values[q.code]
      # add answers
      resp.answers += q.new_answers_from_str(v)
      # reverse-lookup the first location type question we find
      place_bits[:coords] = (v ? v.split(" ")[0..1] : false) if place_bits[:coords].nil? && q.is_location?
      place_bits[:addr] = v || false if place_bits[:addr].nil? && q.is_address?
      # check for start_timestamp
      start_time = v ? Time.parse(v) : false if start_time.nil? && q.is_start_timestamp?
    end
    
    # set the observe time
    resp.observed_at = start_time || nil
    
    # try to get the response's place based on the place bits
    resp.place = Place.find_or_create_with_bits(place_bits)
    
    # save the works, with no validation, since we don't want to lose the data if something goes wrong
    resp.save(:validate => false)
  end
  
  def save_self_and_answers
    # TODO maybe could remove some of this and use validates_associated
    # flag
    answers_valid = true
    begin
      # wrap in a transaction
      transaction do
        # save self
        save
        # save the answers and maintain the flag
        answers.each{|a| a.save || (answers_valid = false)}
        # rollback if self or answers are invalid
        raise ActiveRecord::RecordInvalid.new(self) unless valid? && answers_valid
      end
    # if any validation failed
    rescue ActiveRecord::RecordInvalid
      # add special error to self if answers failed
      errors.add(:base, "One or more answers have errors. Please see below.") unless answers_valid
      # return false to indicate failure
      return false
    end
    true
  end
  
  def update_answers(submitted)
    # do a match on current and newer ids with the ID as the comparator
    answers.match(submitted, Proc.new{|a| a.questioning_id}) do |orig, subd|
      # if both exist, update the original
      if orig && subd
        orig.copy_data_from(subd)
      # if submitted is nil, destroy the original
      elsif subd.nil?
        answers.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        answers << subd
      end
    end
  end
  
  # if a matching answer is not found, initialize one
  def find_or_initialize_answer_for(questioning, option = nil)
    answer_for(questioning, option) || answers.new(:questioning_id => questioning.id)
  end
  
  # returns an answer for the given question
  # if option is specified, we are specifically looking for an answer with the given option
  # on first call, we build a hash of answers to speed lookup
  def answer_for(questioning, option = nil)
    # build the hash
    #unless @answer_hash
      @answer_hash = {}
      answers.each{|a| (@answer_hash[a.questioning] ||= []) << a}
    #end
    
    # get the matching answer(s)
    hits = @answer_hash[questioning] || []
    
    # if option is specified, look for an answer with that option, else just return the first one
    option ? hits.detect{|a| a.option == option} : hits.first
  end
  
  def observed_at_str; observed_at ? observed_at.strftime("%F %l:%M%p %z").gsub("  ", " ") : nil; end
  def observed_at_str=(t); self.observed_at = Time.zone.parse(t); end
  
  def review_count; reviews.count; end
  def form_name; form ? form.name : nil; end
  def submitter; user ? user.full_name : nil; end
  def reviewed?; reviews.size > 0; end
  
  private
    def required_answers
      # add any error for an unanswered questions that require an answer (select_multiples don't count)
      form.questionings.each do |qing| 
        if qing.answer_required? && answer_for(qing).nil?
          errors.add(:base, "Question #{qing.rank} is required.")
        end
      end
    end
end
