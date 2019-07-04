# frozen_string_literal: true

# Class to help search for Responses.
class ResponsesSearcher < Searcher
  # Parsed search values
  attr_accessor :form_ids, :is_reviewed, :submitters, :groups

  def initialize(**opts)
    super(opts)

    self.form_ids = []
    self.submitters = []
    self.groups = []
    self.is_reviewed = nil
  end

  # Returns the list of fields to be searched for this class.
  # Includes whether they should be included in a default, unqualified search
  # and whether they are searchable by a regular expression.
  def search_qualifiers
    [
      Search::Qualifier.new(name: "form", col: "forms.name", assoc: :forms, type: :text),
      Search::Qualifier.new(name: "exact_form", col: "forms.name", assoc: :forms),
      Search::Qualifier.new(name: "reviewed", col: "responses.reviewed", type: :boolean),
      Search::Qualifier.new(name: "submitter", col: "users.name", assoc: :users, type: :text),
      Search::Qualifier.new(name: "group", col: "user_groups.name",
                            assoc: :user_groups, type: :text),
      Search::Qualifier.new(name: "source", col: "responses.source"),
      Search::Qualifier.new(name: "submit_date", type: :date,
                            col: "CAST((responses.created_at AT TIME ZONE 'UTC') AT
                            TIME ZONE '#{Time.zone.tzinfo.name}' AS DATE)"),

      # match responses that have answers to questions with the given option set
      Search::Qualifier.new(name: "option_set", col: "option_sets.name", assoc: :option_sets, type: :text),

      # match responses that have answers to questions with the given type
      # this and other qualifiers use the 'questions' table because the join code below creates a table alias
      # the actual STI table name is 'questions'
      Search::Qualifier.new(name: "question_type", col: "questions.qtype_name", assoc: :questions),

      # match responses that have answers to the given question
      Search::Qualifier.new(name: "question", col: "questions.code", assoc: :questions, type: :text),

      # insert a placeholder that we replace later
      Search::Qualifier.new(name: "text", col: "responses.id", type: :indexed, default: true),
      Search::Qualifier.new(name: "shortcode", col: "responses.shortcode", default: true),

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

  def apply
    search = Search::Search.new(str: query, qualifiers: search_qualifiers)

    self.relation = relation.joins(Results::Join.list_to_sql(search.associations))

    sql = search.sql

    # replace any fulltext search placeholders
    sql = sql.gsub(/###(\d+)###/) do
      # the matched number is the index of the expression in the search's expression list
      expression = search.expressions[Regexp.last_match(1).to_i]

      # search all answers in this mission for a match,
      # not escaping the query value because double quotes were getting escaped
      # which makes exact phrase not work
      attribs = {responses: {mission_id: scope[:mission].id}}

      if expression.qualifier.name == "text_by_code"
        # get qualifier text (e.g. {form}) and strip outer braces
        question_code = expression.qualifier_text[1..-2]

        # get the question with the given code
        question = Question.for_mission(scope[:mission]).with_code(question_code).first

        # this shouldn't happen due to validator
        raise "question with code '#{question_code}' not found" if question.nil?

        # add an attrib to this search
        attribs[:form_items] = {question_id: question.id}
      end

      # Run the full text search and get the matching answer IDs
      answer_ids = Answer.joins(:response, :form_item).where(attribs)
        .search_by_value(expression.values).pluck(:id)

      # turn into an sql fragment
      fragment = if answer_ids.present?
                   # Get all response IDs and join into string
                   Answer.select("response_id").distinct.where(id: answer_ids)
                     .map { |r| "'#{r.response_id}'" }
                     .join(",")
                 end

      # fall back if we get an empty fragment
      fragment.presence || "'00000000-0000-0000-0000-000000000000'"
    end

    save_filter_data(search)

    relation.where(sql)
  end

  private

  # Parse the search expressions and
  # save specific data that can be used for search filters.
  def save_filter_data(search)
    search.expressions.each(&method(:parse_expression))
    clean_up
  end

  # Clean up filter data after parsing everything.
  def clean_up
    self.form_ids = form_ids.uniq
    self.submitters = submitters.uniq
    self.groups = groups.uniq
    self.advanced_text = advanced_text.strip
  end

  # Parse a single expression, saving data that can be used for search filters.
  def parse_expression(expression)
    op_kind = expression.op.kind
    token_values = []
    is_filterable = true
    previous = nil

    expression.leaves.each do |lex_tok|
      is_filterable &&= parse_lex_tok(lex_tok, token_values, previous)
      previous = lex_tok
    end

    maybe_filter_by_expression(expression, op_kind, token_values, is_filterable)
  end

  # Parse a single token in an expression, saving data in the given arrays.
  # Returns false if this token can't be used for search filters (e.g. it contains an AND).
  def parse_lex_tok(lex_tok, token_values, previous)
    # If this is a value token descendant, get the value.
    # Otherwise it's an OR op.
    if lex_tok.parent.is?(:value)
      # If the previous token was also a value token, it's an implicit AND.
      return false if previous&.parent&.is?(:value)

      token_values << lex_tok.content
    end

    true
  end

  # Try to save specific data that can be used for search filters,
  # otherwise fall back to raw search text.
  def maybe_filter_by_expression(expression, op_kind, token_values, is_filterable)
    # Find filters that can be created using the filter UI.
    was_handled = is_filterable &&
      filter_by_expression(expression, op_kind, token_values)

    advanced_text << " #{expression.qualifier_text}:(#{expression.values})" unless was_handled
  end

  # Save specific data that can be used for search filters,
  # or return false if it can't be handled.
  def filter_by_expression(expression, op_kind, token_values)
    return false unless equality_op?(op_kind)

    if expression.qualifier.name == "form"
      return filter_by_names(token_values, Form, current_ids: form_ids)
    elsif expression.qualifier.name == "reviewed"
      return false unless token_values.length == 1
      value = token_values[0]
      return false unless %w[1 0 yes no].include?(value)

      self.is_reviewed = %w[1 yes].include?(value)
      return true
    elsif expression.qualifier.name == "submitter"
      return filter_by_names(token_values, User, current_ids: submitters)
    elsif expression.qualifier.name == "group"
      return filter_by_names(token_values, UserGroup, current_ids: groups)
    end

    false
  end

  # Given a list of names, find all instances of this class that match,
  # and append their IDs to the existing list of IDs to filter by.
  def filter_by_names(names, klass, current_ids: [])
    matched_ids = klass.where("name ILIKE ANY (array[?])", names).pluck(:id)
    return false if matched_ids.empty?
    current_ids.concat(matched_ids)
  end

  def equality_op?(op_kind)
    Search::LexToken::EQUALITY_OPS.include?(op_kind)
  end
end
