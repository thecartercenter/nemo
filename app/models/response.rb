class Response < ApplicationRecord
  extend FriendlyId
  include MissionBased
  include Cacheable

  LOCK_OUT_TIME = 10.minutes
  CODE_CHARS = ("a".."z").to_a + ("0".."9").to_a
  CODE_LENGTH = 5

  acts_as_paranoid

  attr_accessor :modifier, :excerpts, :awaiting_media

  belongs_to :form, inverse_of: :responses, counter_cache: true
  belongs_to :checked_out_by, class_name: "User"
  belongs_to :user, inverse_of: :responses
  belongs_to :reviewer, class_name: "User"

  # response.answers is deprecated in favor of traversing the response tree via response.root_node.children
  has_many :answers, -> { order(:inst_num, :rank) },
    autosave: true, dependent: :destroy, inverse_of: :response
  has_many :location_answers, lambda {
    where("questions.qtype_name = 'location'").order("form_items.rank").includes(questioning: :question)
  }, class_name: "Answer"

  has_closure_tree_root :root_node, class_name: "ResponseNode"

  friendly_id :shortcode

  before_save :normalize_answers
  after_save { root_node.save if root_node.present? }
  before_create :generate_shortcode

  before_destroy :destroy_answer_tree

  # Due to an acts_as_paranoid gem bug, rails counter_cache increments on creation
  # but does not decrement on deletion since we need the counter cache, we'll manually decrement on deletion
  # Issue number: https://github.com/ActsAsParanoid/acts_as_paranoid/issues/39
  after_destroy :update_form_response_count

  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates :user, presence: true
  validate :no_missing_answers
  validate :form_in_mission
  validates_associated :answers # Forces validation of answers even if they haven't changed
  validates_associated :root_node

  scope :unreviewed, -> { where(reviewed: false) }
  scope :by, ->(user) { where(user_id: user.id) }
  scope :created_after, ->(date) { where("responses.created_at >= ?", date) }
  scope :created_before, ->(date) { where("responses.created_at <= ?", date) }
  scope :latest_first, -> { order(created_at: :desc) }

  # loads all the associations required for show, edit, etc.
  scope :with_associations, -> { includes(
    :form,
    {
      answers: [
        {choices: :option},
        :option,
        :media_object,
        { questioning: [:display_conditions, { question: :option_set } ] }
      ]
    },
    :user
  ) }

  # loads basic belongs_to associations
  scope :with_basic_assoc, -> { includes(:form, :user) }

  # loads only some answer info
  scope :with_basic_answers, -> { includes(answers: {questioning: :question}) }

  # loads only answers with location info
  scope :with_location_answers, -> { includes(:location_answers) }

  accepts_nested_attributes_for(:answers, allow_destroy: true)

  delegate :name, to: :checked_out_by, prefix: true
  delegate :questionings, to: :form
  delegate :c, to: :root_node

  def destroy_answer_tree
    root_node.destroy
  end

  # remove previous checkouts by a user
  def self.remove_previous_checkouts_by(user = nil)
    raise ArguementError, "A user is required" unless user

    Response.where(checked_out_by_id: user).update_all(checked_out_at: nil, checked_out_by_id: nil)
  end

  # gets the list of fields to be searched for this class
  # includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression
  def self.search_qualifiers(scope)
    [
      Search::Qualifier.new(name: "form", col: "forms.name", assoc: :forms, type: :text),
      Search::Qualifier.new(name: "exact_form", col: "forms.name", assoc: :forms),
      Search::Qualifier.new(name: "reviewed", col: "responses.reviewed"),
      Search::Qualifier.new(name: "submitter", col: "users.name", assoc: :users, type: :text),
      Search::Qualifier.new(name: "group", col: "user_groups.name",
                            assoc: :user_groups, type: :text),
      Search::Qualifier.new(name: "source", col: "responses.source"),
      Search::Qualifier.new(name: "submit_date", type: :scale,
                            col: "CAST((responses.created_at AT TIME ZONE 'UTC') AT
                              TIME ZONE '#{Time.zone.tzinfo.name}' AS DATE)"),

      # this qualifier matches responses that have answers to questions with the given option set
      Search::Qualifier.new(name: "option_set", col: "option_sets.name", assoc: :option_sets, type: :text),

      # this qualifier matches responses that have answers to questions with the given type
      # this and other qualifiers use the 'questions' table because the join code below creates a table alias
      # the actual STI table name is 'questions'
      Search::Qualifier.new(name: "question_type", col: "questions.qtype_name", assoc: :questions),

      # this qualifier matches responses that have answers to the given question
      Search::Qualifier.new(name: "question", col: "questions.code", assoc: :questions, type: :text),

      # this qualifier inserts a placeholder that we replace later
      Search::Qualifier.new(name: "text", col: "responses.id", type: :indexed, default: true),

      # support {foobar}:stuff style searches, where foobar is a question code
      Search::Qualifier.new(
        name: "text_by_code",
        pattern: /\A\{(#{Question::CODE_FORMAT})\}\z/,
        col: "responses.id",
        type: :indexed,
        validator: ->(md) { Question.for_mission(scope[:mission]).with_code(md[1]).exists? }
      )
    ]
  end

  # searches for responses
  # relation - a Response relation upon which to build the search query
  # query - the search query string (e.g. form:polling text:interference, tomfoolery)
  # scope - the scope to pass to the search qualifiers generator
  # options[:include_excerpts] - if true, execute the query and return the results
  #   with answer excerpts (if applicable) included;
  #   if false, doesn't execute the query and just returns the relation
  # options[:dont_truncate_excerpts] - if true, excerpt length limit is very high,
  #   so full answer is returned with matches highlighted
  def self.do_search(relation, query, scope, options = {})
    options[:include_excerpts] ||= false

    # create a search object and generate qualifiers
    search = Search::Search.new(str: query, qualifiers: search_qualifiers(scope))

    # apply the needed associations
    relation = relation.joins(Results::Join.list_to_sql(search.associations))

    # get the sql
    sql = search.sql

    fulltext_param_sets = []

    # replace any fulltext search placeholders
    sql = sql.gsub(/###(\d+)###/) do
      # the matched number is the index of the expression in the search's expression list
      expression = search.expressions[$1.to_i]

      # search all answers in this mission for a match
      # not escaping the query value because double quotes were getting escaped which makes exact phrase not work
      attribs = {responses: {mission_id: scope[:mission].id}}

      if expression.qualifier.name == "text_by_code"
        # get qualifier text (e.g. {form}) and strip outer braces
        question_code = expression.qualifier_text[1..-2]

        # get the question with the given code
        question = Question.for_mission(scope[:mission]).with_code(question_code).first

        # raising here since this shouldn't happen due to validator
        raise "question with code '#{question_code}' not found" if question.nil?

        # add an attrib to this search
        attribs.merge!({form_items: { question_id: question.id}})
      end

      # Run the full text search and get the matching answer IDs
      answer_ids = Answer.joins(:response, :questioning).where(attribs).
        search_by_value(expression.values).pluck(:id)

      # turn into an sql fragment
      fragment = if answer_ids.present?
        # Get all response IDs and join into string
        Answer.select("response_id").distinct.where(id: answer_ids).map{|r| "'#{r.response_id}'"}.join(",")
      end

      # fall back to 00000000-0000-0000-0000-000000000000' if we get an empty fragment
      fragment.presence || "'00000000-0000-0000-0000-000000000000'"
    end

    # apply the conditions
    relation = relation.where(sql)
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
    where_clause = rel.to_sql.match(/WHERE (.+?)(ORDER BY|\z)/)[1]

    find_by_sql("
      SELECT forms.name AS form_name, COUNT(responses.id) AS count
      FROM responses INNER JOIN forms ON forms.deleted_at IS NULL AND responses.form_id = forms.id
      WHERE responses.deleted_at IS NULL AND #{where_clause}
      GROUP BY forms.id, forms.name
      ORDER BY count DESC
      LIMIT #{n}")
  end

  # generates a cache key for the set of all responses for the given mission.
  # the key will change if the number of responses changes, or if a response is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(rel: for_mission(mission), prefix: "mission-#{mission.id}")
  end

  def self.terminate_sub_relationships(response_ids)
    answer_ids = Answer.where(response_id: response_ids).pluck(:id)
    Choice.where(answer_id: answer_ids).delete_all
    Media::Object.where(answer_id: answer_ids).delete_all
    Answer.where(response_id: response_ids).destroy_all
  end

  # We need a name field so that this class matches the Nameable duck type.
  def name
    "##{id}"
  end

  # whether the answers should validate themselves
  def validate_answers?
    # dont validate if this is an ODK submission as we don't want to lose data
    modifier != "odk"
  end

  # Returns an array of required questionings for which answers are missing.
  def missing_answers
    return @missing_answers if @missing_answers
    answers_by_qing = answers.index_by(&:questioning)
    @missing_answers = questionings.select { |q| q.required? && q.visible? && answers_by_qing[q].nil? }
  end

  # if this response contains location questions, returns the gps location (as a 2 element array)
  # of the first such question on the form, else returns nil
  def location
    ans = location_answers.first
    ans ? ans.location : nil
  end

  # indexes excerpts by questioning_id
  def excerpts_by_questioning_id
    @excerpts_by_questioning_id ||= (excerpts || []).index_by { |e| e[:questioning_id] }
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

  def generate_shortcode
    begin
      response_code = CODE_LENGTH.times.map { CODE_CHARS.sample }.join
      mission_code = mission.shortcode
      # form code should never be nil, because one is generated on publish
      # but we are falling back to "000" just in case something goes wrong
      form_code = form.code || "000"

      self.shortcode = [mission_code, form_code, response_code].join("-")
    end while Response.exists?(shortcode: self.shortcode)
  end

  # TODO: remove in favor of build syntax. SMS parsing needs to be refactored
  # to not rely on this function
  def associate_tree(root)
    associate_node_and_descendants(root)
    self.root_node = root
  end

  def associate_node_and_descendants(node)
    node.response = self
    node.children.each do |child|
      associate_node_and_descendants(child)
    end
  end

  private

  def normalize_answers
    AnswerArranger.new(self, placeholders: :none, dont_load_answers: true).build.normalize
  end

  def form_in_mission
    errors.add(:form, :form_unavailable) unless mission.forms.include?(form)
  end

  def no_missing_answers
    errors.add(:base, :missing_answers) unless missing_answers.empty? || incomplete?
  end

  def update_form_response_count
    Form.reset_counters(form_id, :responses)
  end
end
