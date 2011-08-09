require 'xml'

class Response < ActiveRecord::Base
  belongs_to(:form)
  belongs_to(:place)
  has_many(:answers, :include => :questioning, :order => "questionings.rank", 
    :autosave => true, :validate => false, :dependent => :destroy)
  belongs_to(:user)
  
  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates_associated(:answers, :message => "are invalid (see below)")
  validates(:user, :presence => true)
  validates(:observed_at, :presence => true)
  validate(:no_missing_answers)
  
  def self.sorted(params = {})
    params.merge!(:order => "responses.created_at desc")
    paginate(:all, params)
  end
  
  def self.default_eager
    [{:form => :type}, :user, :place]
  end
  
  def self.find_eager(id)
    find(id, :include => [
      :form,
      {:answers => 
        [{:choices => {:option => :translations}},
         {:option => :translations}, 
         {:questioning => {:question => 
           [:type, :translations, {:option_set => {:options => :translations}}]
         }}
        ]
      }
    ])
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
    qings = resp.form ? resp.form.visible_questionings : (raise ArgumentError.new("Invalid form id."))
    
    # loop over each child tag and create hash of question_code => value
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}
    
    # loop over all the questions in the form and create answers
    place_bits = {}
    start_time = nil
    qings.each do |qing|
      # get value from hash
      str = values[qing.question.code]
      # add answer
      resp.answers << Answer.new_from_str(:str => str, :questioning => qing)
      
      # pull out the place bits and start time as we find them
      if place_bits[:coords].nil? && qing.question.is_location?
        place_bits[:coords] = (str ? str.split(" ")[0..1] : false)
      elsif place_bits[:addr].nil? && qing.question.is_address?
        place_bits[:addr] = str || false
      elsif start_time.nil? && qing.question.is_start_timestamp?
        start_time = str ? Time.parse(str) : false
      end
    end
    
    # set the observe time
    resp.observed_at = start_time || nil
    
    # try to get the response's place based on the place bits
    resp.place = Place.find_or_create_with_bits(place_bits)
    
    # save the works
    resp.save!
  end
  
  def visible_questionings
    # get visible questionings from form, throwing out phone_only's when appropriate
    form.visible_questionings.reject{|qing| qing.question.type.phone_only? && (new_record? || !answer_for(qing))}
  end
  
  def all_answers
    # make sure there is an associated answer object for each questioning in the form
    visible_questionings.collect{|qing| answer_for(qing) || answers.new(:questioning_id => qing.id)}
  end
  
  def all_answers=(params)
    # do a match on current and newer ids with the ID as the comparator
    answers.match(params.values, Proc.new{|a| a[:questioning_id].to_i}) do |orig, subd|
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
  
  def observed_at_str; observed_at ? observed_at.strftime("%F %l:%M%p %z").gsub("  ", " ") : nil; end
  def observed_at_str=(t); self.observed_at = Time.zone.parse(t); end
  
  def form_name; form ? form.name : nil; end
  def submitter; user ? user.full_name : nil; end
  
  private
    def no_missing_answers
      answer_hash(:rebuild => true)
      visible_questionings.each do |qing|
        errors.add(:base, "Not all questions have answers") and return false if answer_for(qing).nil?
      end
    end
end
