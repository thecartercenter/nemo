# models the various joins in the Response/Answer db structure
class Report::Join

  attr_reader :name, :sql, :dependencies

  def self.list_to_sql(list, prefix = "")
    expand(list).collect{|join| join.to_sql(prefix)}
  end

  def self.expand(list)
    expanded = []
    list.each{|j| expanded += @@joins[j.to_sym].expand}
    expanded.flatten.uniq
  end

  def initialize(params)
    @sql = params[:sql]
    @name = params[:name]
    @dependencies = params[:dependencies] ? (params[:dependencies].is_a?(Symbol) ? [params[:dependencies]] : params[:dependencies]) : []
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
    :answers => new(
      :name => :answers,                                              # no __ here b/c responses never needs to be prefixed
      :sql => "LEFT JOIN answers __answers ON __answers.response_id = responses.id"
    ),
    :questionings => new(
      :dependencies => :answers,
      :name => :questionings,
      :sql => "INNER JOIN form_items __questionings ON __answers.questioning_id = __questionings.id"
    ),
    :questions => new(
      :name => :questions,
      :dependencies => :questionings,
      :sql => "INNER JOIN questions __questions ON __questionings.question_id = __questions.id"
    ),
    :option_sets => new(
      :name => :option_sets,
      :dependencies => :questions,
      :sql => "LEFT JOIN option_sets __option_sets ON __questions.option_set_id = __option_sets.id"
    ),
    :options => new(
      :dependencies => [:answers, :option_sets],
      :name => :options,
      :sql => [
        "LEFT JOIN options __ao ON __answers.option_id = __ao.id",
        "LEFT JOIN option_nodes __ans_opt_nodes ON __ans_opt_nodes.option_id = __ao.id " +
          "AND __ans_opt_nodes.option_set_id = __option_sets.id"
      ]
    ),
    :choices => new(
      :dependencies => [:answers, :option_sets],
      :name => :choices,
      :sql => [
        "LEFT JOIN choices __choices ON __choices.answer_id = __answers.id",
        "LEFT JOIN options __co ON __choices.option_id = __co.id",
        "LEFT JOIN option_nodes __ch_opt_nodes ON __ch_opt_nodes.option_id = __co.id " +
          "AND __ch_opt_nodes.option_set_id = __option_sets.id"
      ]
    ),
    :forms => new(
      :name => :forms,
      :sql => "INNER JOIN forms __forms ON responses.form_id = __forms.id"
    ),
    :users => new(
      :name => :users,
      :sql => "LEFT JOIN users __users ON responses.user_id = __users.id"
    )
  }
end