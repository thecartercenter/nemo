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
      :sql => "INNER JOIN questionings __questionings ON __answers.questioning_id = __questionings.id"
    ),      
    :options => new(
      :dependencies => :answers,
      :name => :options,
      :sql => ["LEFT JOIN options __ao ON __answers.option_id = __ao.id",
        "LEFT JOIN translations __aotr ON (__aotr.obj_id = __ao.id and __aotr.fld = 'name' and __aotr.class_name = 'Option' " +
          "AND __aotr.language = 'eng')"]
    ),      
    :choices => new(
      :dependencies => :answers,
      :name => :choices,
      :sql => ["LEFT JOIN choices __choices ON __choices.answer_id = __answers.id",
        "LEFT JOIN options __co ON __choices.option_id = __co.id",
        "LEFT JOIN translations __cotr ON (__cotr.obj_id = __co.id and __cotr.fld = 'name' and __cotr.class_name = 'Option' " + 
            "AND __cotr.language = 'eng')"]
    ),      
    :forms => new(
      :name => :forms,
      :sql => "INNER JOIN forms __forms ON responses.form_id = __forms.id"
    ),      
    :form_types => new(
      :name => :form_types,
      :dependencies => :forms, 
      :sql => "INNER JOIN form_types __form_types ON __forms.form_type_id = __form_types.id"
    ),      
    :questions => new(
      :name => :questions,
      :dependencies => :questionings,
      :sql => "INNER JOIN questions __questions ON __questionings.question_id = __questions.id"
    ),
    :question_trans => new(
      :name => :question_trans,
      :dependencies => :questions,
      :sql => "INNER JOIN translations __question_trans ON (__question_trans.obj_id = __questions.id 
        AND __question_trans.fld = 'name' AND __question_trans.class_name = 'Question' 
        AND __question_trans.language = 'eng')"
    ),
    :question_types => new( 
      :name => :question_types,
      :dependencies => :questions, 
      :sql => "INNER JOIN question_types __question_types ON __questions.question_type_id = __question_types.id"
    ),      
    :option_sets => new( 
      :name => :option_sets,
      :dependencies => :questions, 
      :sql => "LEFT JOIN option_sets __option_sets ON __questions.option_set_id = __option_sets.id"
    ),
    :users => new(
      :name => :users,
      :sql => "LEFT JOIN users __users ON responses.user_id = __users.id"
    )
  }       
end