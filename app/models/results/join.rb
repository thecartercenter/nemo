# models the various joins in the Response/Answer db structure
class Results::Join

  attr_reader :name, :sql, :dependencies

  def self.list_to_sql(*list, prefix: "")
    expand(list.flatten).map { |j| j.to_sql(prefix) }
  end

  def self.expand(list)
    expanded = []
    list.each { |j| expanded += @@joins[j.to_sym].expand }
    expanded.flatten.uniq
  end

  def initialize(params)
    @sql = params[:sql]
    @name = params[:name]
    @dependencies = if params[:dependencies]
      params[:dependencies].is_a?(Symbol) ? [params[:dependencies]] : params[:dependencies]
    else
      []
    end
  end

  # expands dependencies to find all necessary joins
  def expand
    (dependencies ? dependencies.collect{|dep| @@joins[dep].expand}.flatten : []) + [self]
  end

  # returns the appropriate sql for the given join, adding the optional prefix to all table names
  def to_sql(prefix = "")
    prefix += "_" unless prefix.blank?
    Array.wrap(sql).join(" ").gsub(/__/, prefix)
  end

  @@joins = {
    # Note there is no __ on responses below b/c responses never needs to be prefixed
    answers: new(
      name: :answers,
      sql: "LEFT JOIN answers __answers ON __answers.response_id = responses.id " \
        "AND __answers.deleted_at IS NULL AND __answers.type = 'Answer'"
    ),
    questionings: new(
      dependencies: :answers,
      name: :questionings,
      sql: "INNER JOIN form_items __questionings ON __answers.questioning_id = __questionings.id " \
        "AND __questionings.deleted_at IS NULL"
    ),
    questions: new(
      name: :questions,
      dependencies: :questionings,
      sql: "INNER JOIN questions __questions ON __questionings.question_id = __questions.id " \
        "AND __questions.deleted_at IS NULL"
    ),
    option_sets: new(
      name: :option_sets,
      dependencies: :questions,
      sql: "LEFT JOIN option_sets __option_sets ON __questions.option_set_id = __option_sets.id " \
        "AND __option_sets.deleted_at IS NULL"
    ),
    options: new(
      dependencies: [:answers, :option_sets],
      name: :options,
      sql: [
        "LEFT JOIN options __ao ON __answers.option_id = __ao.id " \
          "AND __ao.deleted_at IS NULL",
        "LEFT JOIN option_nodes __ans_opt_nodes ON __ans_opt_nodes.option_id = __ao.id " \
          "AND __ans_opt_nodes.option_set_id = __option_sets.id " \
          "AND __ans_opt_nodes.deleted_at IS NULL"
      ]
    ),
    choices: new(
      dependencies: [:answers, :option_sets],
      name: :choices,
      sql: [
        "LEFT JOIN choices __choices ON __choices.answer_id = __answers.id " \
          "AND __choices.deleted_at IS NULL",
        "LEFT JOIN options __co ON __choices.option_id = __co.id " \
          "AND __co.deleted_at IS NULL",
        "LEFT JOIN option_nodes __ch_opt_nodes ON __ch_opt_nodes.option_id = __co.id " \
          "AND __ch_opt_nodes.option_set_id = __option_sets.id " \
          "AND __ch_opt_nodes.deleted_at IS NULL"
      ]
    ),
    forms: new(
      name: :forms,
      sql: "INNER JOIN forms __forms ON responses.form_id = __forms.id " \
        "AND __forms.deleted_at IS NULL"
    ),
    users: new(
      name: :users,
      sql: "LEFT JOIN users __users ON responses.user_id = __users.id " \
              "AND __users.deleted_at IS NULL"
    ),
    user_groups: new(
      dependencies: [:users],
      name: :user_groups,
      sql: "LEFT JOIN user_group_assignments __user_group_assignments ON " \
             "__user_group_assignments.user_id = __users.id " \
           "LEFT JOIN user_groups __user_groups ON " \
             "__user_group_assignments.user_group_id = __user_groups.id"
    ),
    reviewers: new(
      name: :reviewers,
      sql: "LEFT JOIN users __reviewers ON responses.reviewer_id = __reviewers.id " \
        "AND __reviewers.deleted_at IS NULL"
    )
  }
end
