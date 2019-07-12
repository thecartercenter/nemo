# frozen_string_literal: true

# Class to help search for Responses.
class ResponsesSearcher < Searcher
  # Parsed search values
  attr_accessor :form_ids, :qings, :is_reviewed, :submitters, :groups

  def initialize(**opts)
    super(opts)

    self.form_ids = []
    self.qings = []
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
    return relation if query.blank?

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

  def all_forms
    Form.for_mission(scope[:mission])
      .map { |item| {name: item.name, id: item.id} }
      .sort_by_key || []
  end

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

    # Text/shortcode is always filterable.
    unless %w[text shortcode].include?(expression.qualifier.name.downcase)
      expression.leaves.each do |lex_tok|
        is_filterable &&= parse_lex_tok(lex_tok, token_values, previous)
        previous = lex_tok
      end
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

    advanced_text << " #{advanced_text_string(expression)}" unless was_handled
  end

  # Save specific data that can be used for search filters,
  # or return false if it can't be handled.
  def filter_by_expression(expression, op_kind, token_values)
    return false unless equality_op?(op_kind)

    case expression.qualifier.name.downcase
    when "form"
      filter_by_names(token_values, Form, current_ids: form_ids)
    when "text_by_code"
      filter_by_questions(expression.qualifier_text, token_values)
    when "reviewed"
      filter_by_is_reviewed(token_values)
    when "submitter"
      filter_by_names(token_values, User, current_ids: submitters, include_name: true)
    when "group"
      filter_by_names(token_values, UserGroup, current_ids: groups, include_name: true)
    when "text"
      advanced_text << " #{expression.values}"
      true
    when "shortcode"
      # Skip to prevent duplicate handling as `text`.
      true
    else
      false
    end
  end

  # Given a list of values, find all instances of this class that match,
  # and append their IDs to the existing list of IDs to filter by.
  # Returns false if unable to handle this case.
  def filter_by_names(names, klass, current_ids: [], include_name: false)
    matches = klass.where("LOWER(name) = ANY (ARRAY[?])", names.map(&:downcase)).pluck(:id, :name)
    return false if matches.empty?
    current_ids.concat(matches.map { |id, name| include_name ? {id: id, name: name} : id })
    true
  end

  # Determine if is_reviewed is a valid boolean and filter by it.
  # Returns false if unable to handle this case.
  def filter_by_is_reviewed(token_values)
    return false unless token_values.length == 1
    value = token_values[0].downcase
    return false unless %w[1 0 yes no].include?(value)
    self.is_reviewed = %w[1 yes].include?(value)
    true
  end

  # Filter by a question code + question value.
  # Returns false if unable to handle this case.
  def filter_by_questions(qualifier_text, token_values)
    return false unless token_values.length == 1
    # Strip the surrounding {QuestionCode} braces.
    question_code = qualifier_text[1..-2]
    matched_question = Question.where("LOWER(code) = ?", question_code.downcase).first
    return false if matched_question.blank?
    matched_qings = Questioning.where(question: matched_question)
    return false if matched_qings.blank?
    # Get the deterministic Questioning ID from the Question
    matched_qing_id = matched_qings.filter_unique.first.id
    value = qing_value(matched_question, token_values)
    qings.concat([{id: matched_qing_id}.merge(value)])
    true
  end

  # Get the qing value from the user input (either a string to match or an Option ID).
  def qing_value(matched_question, token_values)
    value = token_values[0]
    return {value: value} unless matched_question.option_set_id
    {option_node_id: find_option_node_id(matched_question.option_set_id, value)}
  end

  def find_option_node_id(option_set_id, value)
    partial_match = OptionNode.joins(:option).includes(:option)
      .where(option_set_id: option_set_id)

    # TODO: Can this be more efficient?
    # Doesn't work with jsonb: `partial_match.where("options.name_translations ILIKE ?", value)`
    value = value.downcase
    full_match = partial_match.where("LOWER(options.canonical_name) = ?", value) +
      partial_match.select do |node|
        node.option.name_translations.values.map(&:downcase).include?(value)
      end

    full_match.pluck(:id).first
  end

  def equality_op?(op_kind)
    Search::LexToken::EQUALITY_OPS.include?(op_kind)
  end

  # Stringify an expression for the advanced text search box.
  def advanced_text_string(expression)
    lhs = expression.qualifier_text
    op = expression.op.content
    rhs = expression.values
    # Conservative check: if it includes whitespace, wrap in parens.
    # Any quotes will also be preserved, regardless.
    rhs = "(#{rhs})" if rhs.match?(/\s/)
    "#{lhs}#{op}#{rhs}"
  end
end
