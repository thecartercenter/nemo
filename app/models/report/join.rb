# models the various joins in the Response/Answer db structure
class Report::Join
  
  attr_reader :name, :sql, :dependencies

  def self.list_to_sql(list)
    expanded = []
    list.each{|j| expanded += @@joins[j.to_sym].expand}
    expanded = expanded.flatten.uniq
    expanded.collect{|join| join.sql}
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
  
  @@joins = {
    :answers => new(
      :name => :answers,
      :sql => "LEFT JOIN answers ON answers.response_id = responses.id"
    ),
    :questionings => new(
      :dependencies => :answers,
      :name => :questionings, 
      :sql => "INNER JOIN questionings ON answers.questioning_id = questionings.id"
    ),      
    :options => new(
      :dependencies => :answers,
      :name => :options,
      :sql => ["LEFT JOIN options ao ON answers.option_id = ao.id",
        "LEFT JOIN translations aotr ON (aotr.obj_id = ao.id and aotr.fld = 'name' and aotr.class_name = 'Option' " +
          "AND aotr.language = 'eng')"]
    ),      
    :choices => new(
      :dependencies => :answers,
      :name => :choices,
      :sql => ["LEFT JOIN choices ON choices.answer_id = answers.id",
        "LEFT JOIN options co ON choices.option_id = co.id",
        "LEFT JOIN translations cotr ON (cotr.obj_id = co.id and cotr.fld = 'name' and cotr.class_name = 'Option' " + 
            "AND cotr.language = 'eng')"]
    ),      
    :forms => new(
      :name => :forms,
      :sql => "INNER JOIN forms ON responses.form_id = forms.id"
    ),      
    :form_types => new(
      :name => :form_types,
      :dependencies => :forms, 
      :sql => "INNER JOIN form_types ON forms.form_type_id = form_types.id"
    ),      
    :questions => new(
      :name => :questions,
      :dependencies => :questionings,
      :sql => "INNER JOIN questions ON questionings.question_id = questions.id"
    ),
    :question_trans => new(
      :name => :question_trans,
      :dependencies => :questions,
      :sql => "INNER JOIN translations question_trans ON (question_trans.obj_id = questions.id 
        AND question_trans.fld = 'name' AND question_trans.class_name = 'Question' 
        AND question_trans.language = 'eng')"
    ),
    :question_types => new( 
      :name => :question_types,
      :dependencies => :questions, 
      :sql => "INNER JOIN question_types ON questions.question_type_id = question_types.id"
    ),      
    :option_sets => new( 
      :name => :option_sets,
      :dependencies => :questions, 
      :sql => "LEFT JOIN option_sets ON questions.option_set_id = option_sets.id"
    ),
    :users => new(
      :name => :users,
      :sql => "LEFT JOIN users ON responses.user_id = users.id"
    )
  }       
end