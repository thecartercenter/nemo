require 'xml'
class Response < ActiveRecord::Base
  include MissionBased
  include Cacheable

  LOCK_OUT_TIME = 10.minutes

  belongs_to(:form, :inverse_of => :responses, :counter_cache => true)
  belongs_to(:checked_out_by, :class_name => "User")
  has_many(:answers, :include => :questioning, :order => 'form_items.rank, answers.rank',
    :autosave => true, :dependent => :destroy, :inverse_of => :response)
  belongs_to(:user, :inverse_of => :responses)

  has_many(:location_answers, :include => {:questioning => :question}, :class_name => 'Answer',
    :conditions => "questions.qtype_name = 'location'", :order => 'form_items.rank')

  attr_accessor(:modifier, :excerpts)

  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates(:user, :presence => true)
  validate(:no_missing_answers)

  default_scope(includes(:form, :user).order("responses.created_at DESC"))
  scope(:unreviewed, where(:reviewed => false))
  scope(:by, lambda{|user| where(:user_id => user.id)})

  # loads all the associations required for show, edit, etc.
  scope(:with_associations, includes(
    :form, {
      :answers => [
        {:choices => :option},
        :option,
        {:questioning => [:condition, {:question => :option_set}]}
      ]
    }
  ))

  # loads basic belongs_to associations
  scope(:with_basic_assoc, includes(:form, :user))

  # loads only some answer info
  scope(:with_basic_answers, includes(:answers => {:questioning => :question}))

  # loads only answers with location info
  scope(:with_location_answers, includes(:location_answers))

  accepts_nested_attributes_for(:answers)

  delegate :name, :to => :checked_out_by, :prefix => true
  delegate :visible_questionings, to: :form

  # remove previous checkouts by a user
  def self.remove_previous_checkouts_by(user = nil)
    raise ArguementError, "A user is required" unless user

    Response.where(:checked_out_by_id => user).update_all(:checked_out_at => nil, :checked_out_by_id => nil)
  end

  # takes a Relation, adds a bunch of selects and joins, and uses find_by_sql to do the actual finding
  # this technique is due to limitations (at the time of dev) in the Relation system
  def self.for_export(rel)
    find_by_sql(export_sql(rel))
  end

  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_qualifiers(scope)
    [
      Search::Qualifier.new(:name => "form", :col => "forms.name", :assoc => :forms),
      Search::Qualifier.new(:name => "reviewed", :col => "responses.reviewed"),
      Search::Qualifier.new(:name => "submitter", :col => "users.name", :assoc => :users, :type => :text),
      Search::Qualifier.new(:name => "source", :col => "responses.source"),
      Search::Qualifier.new(:name => "submit_date", :col => "DATE(CONVERT_TZ(responses.created_at, 'UTC', '#{Time.zone.mysql_name}'))", :type => :scale),

      # this qualifier matches responses that have answers to questions with the given option set
      Search::Qualifier.new(:name => "option_set", :col => "option_sets.name", :assoc => :option_sets),

      # this qualifier matches responses that have answers to questions with the given type
      # this and other qualifiers use the 'questions' table because the join code below creates a table alias
      # the actual STI table name is 'questions'
      Search::Qualifier.new(:name => "question_type", :col => "questions.qtype_name", :assoc => :questions),

      # this qualifier matches responses that have answers to the given question
      Search::Qualifier.new(:name => "question", :col => "questions.code", :assoc => :questions),

      # this qualifier inserts a placeholder that we replace later
      Search::Qualifier.new(:name => "text", :col => "responses.id", :type => :indexed, :default => true),

      # support {foobar}:stuff style searches, where foobar is a question code
      Search::Qualifier.new(:name => "text_by_code", :pattern => /^\{(#{Question::CODE_FORMAT})\}$/, :col => "responses.id",
        :type => :indexed, :validator => ->(md){ Question.exists?(:mission_id => scope[:mission].id, :code => md[1]) })
    ]
  end

  # searches for responses
  # relation - a Response relation upon which to build the search query
  # query - the search query string (e.g. form:polling text:interference, tomfoolery)
  # scope - the scope to pass to the search qualifiers generator
  # options[:include_excerpts] - if true, execute the query and return the results with answer excerpts (if applicable) included;
  #   if false, doesn't execute the query and just returns the relation
  # options[:dont_truncate_excerpts] - if true, excerpt length limit is very high, so full answer is returned with matches highlighted
  def self.do_search(relation, query, scope, options = {})
    options[:include_excerpts] ||= false

    # create a search object and generate qualifiers
    search = Search::Search.new(:str => query, :qualifiers => search_qualifiers(scope))

    # apply the needed associations
    relation = relation.joins(Report::Join.list_to_sql(search.associations))

    # get the sql
    sql = search.sql

    sphinx_param_sets = []

    # replace any fulltext search placeholders
    sql = sql.gsub(/###(\d+)###/) do
      # the matched number is the index of the expression in the search's expression list
      expression = search.expressions[$1.to_i]

      # search all answers in this mission for a match
      # not escaping the query value because double quotes were getting escaped which makes exact phrase not work
      attribs = {:mission_id => scope[:mission].id}

      if expression.qualifier.name == "text_by_code"
        # get qualifier text (e.g. {form}) and strip outer braces
        question_code = expression.qualifier_text[1..-2]

        # get the question with the given code
        question = Question.where(:mission_id => scope[:mission].id).where(:code => question_code).first

        # raising here since this shouldn't happen due to validator
        raise "question with code '#{question_code}' not found" if question.nil?

        # add an attrib to this sphinx search
        attribs[:question_id] = question.id
      end

      # save the search params as we'll need them again
      sphinx_params = [expression.values, {:with => attribs, :max_matches => 1000000, :per_page => 1000000}]
      sphinx_param_sets << sphinx_params

      # run the sphinx search
      answer_ids = Answer.search_for_ids(*sphinx_params)

      # turn into an sql fragment
      fragment = if answer_ids.present?
        # get all response IDs and join into string
        Answer.connection.execute("SELECT DISTINCT response_id FROM answers WHERE answers.id IN (#{answer_ids.join(',')})").to_a.flatten.join(',')
      end

      # fall back to '0' if we get an empty fragment
      fragment.presence || '0'
    end

    # apply the conditions
    relation = relation.where(sql)

    # do excerpts
    if !sphinx_param_sets.empty? && options[:include_excerpts]

      # get matches
      responses = relation.all

      unless responses.empty?
        responses_by_id = responses.index_by(&:id)

        # run answer searches again, but this time restricting response_ids to the matches responses
        sphinx_param_sets.each do |sphinx_params|

          # run search again
          sphinx_params[1][:with][:response_id] = responses_by_id.keys
          sphinx_params[1][:sql] = {:include => {:questioning => :question}}
          answers = Answer.search(*sphinx_params)

          excerpter_options = {:before_match => '{{{', :after_match => '}}}', :chunk_separator => ' ... ', :query_mode => true}
          excerpter_options[:limit] = 1000000 if options[:dont_truncate_excerpts]

          # create excerpter
          excerpter = ThinkingSphinx::Excerpter.new('answer_core', sphinx_params[0], excerpter_options)

          # for each matching answer, add to excerpt to appropriate response
          answers.each do |a|
            r = responses_by_id[a.response_id]
            r.excerpts ||= []
            r.excerpts << {:questioning_id => a.questioning_id, :code => a.questioning.code, :text => excerpter.excerpt!(a.value)}
          end
        end
      end

      # return responses
      responses
    else
      # no excerpts, just return the relation
      relation
    end
  end

  # returns a count how many responses have arrived recently
  # format e.g. [5, "week"] (5 in the last week)
  # nil means no recent responses
  def self.recent_count(rel)
    %w(hour day week month year).each do |p|
      if (count = rel.where("created_at > ?", 1.send(p).ago).count) > 0
        return [count, p]
      end
    end
    nil
  end

  # returns an array of N response counts grouped by form
  # uses the WHERE clause from the given relation
  def self.per_form(rel, n)
    where_clause = rel.arel.send(:where_clauses).join(' AND ')
    where_clause = '1=1' if where_clause.empty?

    find_by_sql("
      SELECT forms.name AS form_name, COUNT(responses.id) AS count
      FROM responses INNER JOIN forms ON responses.form_id = forms.id
      WHERE #{where_clause}
      GROUP BY forms.id, forms.name
      ORDER BY count DESC
      LIMIT #{n}")
  end

  # generates a cache key for the set of all responses for the given mission.
  # the key will change if the number of responses changes, or if a response is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(:rel => unscoped.for_mission(mission), :prefix => "mission-#{mission.id}")
  end

  # We need a name field so that this class matches the Nameable duck type.
  def name
    "##{id}"
  end

  # whether the answers should validate themselves
  def validate_answers?
    # dont validate if this is an ODK submission as we don't want to lose data
    modifier != 'odk'
  end

  def populate_from_odk(xml)
    # Response mission should already be set
    raise "Submissions must have a mission" if mission.nil?

    self.source = 'odk'

    data = XML::Parser.string(xml).parse.root

    lookup_and_check_form(:id => data['id'], :version => data['version'])

    # Loop over each child tag and create hash of odk_code => value
    hash = Hash[*data.children.map{|c| [c.name, c.first.try(:content)]}.flatten(1)]

    populate_from_hash(hash)
  end

  def populate_from_j2me(data)
    # Response mission should already be set
    raise "Submissions must have a mission" if mission.nil?

    self.source = 'j2me'

    lookup_and_check_form(:id => data.delete('id'), :version => data.delete('version'))

    # Get rid of other unneeded keys.
    data = data.except(*%w(uiVersion name xmlns xmlns:jrm))

    populate_from_hash(data)
  end

  # Groups answers by questioning.
  # Makes sure there are associated answer objects for each questioning in the form.
  def answer_sets
    @answer_sets ||= visible_questionings.map{ |qing| answer_set_for_questioning(qing) }
  end

  def answer_for_question(question)
    (@answers_by_question ||= answers.index_by(&:question))[question]
  end

  def answer_for_qing(qing)
    (@answers_by_qing ||= answers.index_by(&:questioning))[qing]
  end

  # Returns an array of required questionings for which answers are missing.
  # Used in cases other than the web form where answer objects may not be created for missing answers.
  def missing_answers
    @missing_answers ||= visible_questionings.select{ |qing| qing.required? && answer_for_qing(qing).nil? }
  end

  # if this response contains location questions, returns the gps location (as a 2 element array)
  # of the first such question on the form, else returns nil
  def location
    ans = location_answers.first
    ans ? ans.location : nil
  end

  # indexes excerpts by questioning_id
  def excerpts_by_questioning_id
    @excerpts_by_questioning_id ||= (excerpts || []).index_by{|e| e[:questioning_id]}
  end

  def check_out_valid?
    checked_out_at > Response::LOCK_OUT_TIME.ago
  end

  def checked_out_by_others?(user = nil)
    raise ArguementError, "A user is required" unless user

    !self.checked_out_by.nil? && self.checked_out_by != user && check_out_valid?
  end

  def check_out!(user = nil)
    raise ArgumentError, "A user is required to checkout a response" unless user

    if !checked_out_by_others?(user)
      transaction do
        Response.remove_previous_checkouts_by(user)

        self.checked_out_at = Time.now
        self.checked_out_by = user
        save(validate: false)
      end
    end
  end

  def check_in
    self.checked_out_at = nil
    self.checked_out_by_id = nil
  end

  def check_in!
    self.check_in
    self.save!
  end

  private
    def self.export_sql(rel)
      # add all the selects
      # assumes the language desired is English. currently does not respect the locale
      rel = rel.select("responses.id AS response_id")
      rel = rel.select("responses.created_at AS submission_time")
      rel = rel.select("responses.reviewed AS is_reviewed")
      rel = rel.select("forms.name AS form_name")

      rel = rel.select("questions.code AS question_code")
      rel = rel.select("questions.canonical_name AS question_name")
      rel = rel.select("questions.qtype_name AS question_type")

      rel = rel.select("users.name AS submitter_name")
      rel = rel.select("answers.id AS answer_id")
      rel = rel.select("answers.value AS answer_value")
      rel = rel.select("answers.datetime_value AS answer_datetime_value")
      rel = rel.select("answers.date_value AS answer_date_value")
      rel = rel.select("answers.time_value AS answer_time_value")
      rel = rel.select("IFNULL(ao.canonical_name, co.canonical_name) AS choice_name")
      rel = rel.select("option_sets.name AS option_set")

      # add all the joins
      rel = rel.joins(Report::Join.list_to_sql([:users, :forms,
        :answers, :questionings, :questions, :option_sets, :options, :choices]))

      rel.to_sql
    end

    def no_missing_answers
      errors.add(:base, :missing_answers) unless missing_answers.empty? || incomplete?
    end

    # Checks if form ID and version were given, if form exists, and if version is correct
    def lookup_and_check_form(params)
      # if either of these is nil or not an integer, error
      raise SubmissionError.new("no form id was given") if params[:id].nil?
      raise FormVersionError.new("form version must be specified") if params[:version].nil?

      # try to load form (will raise activerecord error if not found)
      self.form = Form.find(params[:id])

      # if form has no version, error
      raise "xml submissions must be to versioned forms" if form.current_version.nil?

      # if form version is outdated, error
      raise FormVersionError.new("form version is outdated") if form.current_version.sequence > params[:version].to_i
    end

    # Populates response given a hash of odk-style question codes (e.g. q5, q7_1) to string values.
    def populate_from_hash(hash)
      form.visible_questionings.each do |qing|
        qing.subquestions.each do |subq|
          answer = Answer.new(questioning: qing, rank: subq.rank)
          answer.populate_from_string(hash[subq.odk_code])
          self.answers << answer
        end
      end
      self.incomplete = (hash[OdkHelper::IR_QUESTION] == 'yes')
    end

    def answer_set_for_questioning(questioning)
      # If answer set already exists, it will be in the answer_sets_by_questioning hash, else create a new one.
      answer_sets_by_questioning[questioning] || AnswerSet.new(questioning: questioning)
    end

    # Builds a hash of questionings to answer sets.
    def answer_sets_by_questioning
      @answer_sets_by_questioning ||= {}.tap do |hash|
        answers.group_by(&:questioning).each{ |q, a| hash[q] = AnswerSet.new(questioning: q, answers: a) }
      end
    end
end
