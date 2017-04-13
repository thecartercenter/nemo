class ResponseCSV
  def initialize(responses)
    @responses = responses
    @columns = []
    @columns_by_question = {}
    @processed_forms = []
  end

  def to_s
    @str ||= responses.empty? ? "" : generate
  end

  private

  attr_accessor :responses, :columns, :columns_by_question, :processed_forms

  def generate
    # We have to build the body first so that the headers are correct.
    b = body
    headers << b
  end

  def headers
    CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
      csv << columns
    end
  end

  def body
    CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
      # Initial columns
      find_or_create_column(code: "Form")
      find_or_create_column(code: "Submitter")
      find_or_create_column(code: "DateSubmitted")
      find_or_create_column(code: "ResponseID")

      responses.each do |response|
        # Ensure we have all this response's columns in our table.
        process_form(response.form)

        # Split response into repeatable and non-repeatable answers. There will be one row with the non
        # repeat answers, and then one row for each repeat group answer.
        answers = response.answers.includes(:questioning, :option, choices: :option).order(:questioning_id, :inst_num, :rank)
        repeatable_answers = answers.select{ |a| a.questioning.parent_repeatable? }
        non_repeat_answers = answers - repeatable_answers

        # make initial row
        row = [
          response.form.name,
          response.user.name,
          response.created_at.to_s(:std_datetime_with_tz),
          response.id
        ]

        non_repeat_answers.group_by(&:question).each do |question, answers|
          add_question_answers_to_row(response, row, question, answers)
        end
        repeating_row_part = row.dup
        ensure_row_complete(row)
        csv << row

        #Make a row for each repeat_group answer
        repeat_groups = repeatable_answers.group_by { |a| a.questioning.parent }
        repeat_groups.each do |repeat_group, group_answers|
          group_answers.group_by(&:inst_num).each do |inst_num, repeat_answers|
            row = repeating_row_part.dup
            repeat_answers.group_by(&:question).each do |question, answers|
              add_question_answers_to_row(response, row, question, answers)
            end
            ensure_row_complete(row)
            csv << row
          end
        end
      end
    end
  end

  def add_question_answers_to_row(response, row, question, answers)
    return if question.multimedia?
    columns = columns_by_question[question.code]
    qa = ResponseCSV::QA.new(question, answers)
    columns.each_with_index{ |c, i| row[c.position] = qa.cells[i] }
    if response.form.has_repeat_groups?
      repeat_level = answers.first.repeat_level
      repeat_group_name = answers.first.repeat_group_name
      row[columns_by_question["RepeatGroupName"].first.position] = repeat_group_name
      row[columns_by_question["RepeatLevel"].first.position] = repeat_level
    end
  end

  def ensure_row_complete(row)
    if row.count < columns.count
      row[columns.count - 1] = nil
    end
  end

  def process_form(form)
    return if processed_forms.include?(form.id)
    form.questions.each{ |q| find_or_create_column(question: q) }
    if form.has_repeat_groups?
      find_or_create_column(code: "RepeatGroupName")
      find_or_create_column(code: "RepeatLevel")
    end
    processed_forms << form.id
  end

  def find_or_create_column(code: nil, question: nil)
    code ||= question.code

    return if column_exists_with_code?(code)

    if question
      return if question.multimedia?
      if question.multilevel?
        question.levels.each_with_index do |level, i|
          create_column(code: code, name: [code, level.name])
        end
      else
        # Location questions only have lng/lat cols which are added below.
        unless question.qtype_name == 'location'
          create_column(code: code)
        end
      end
      if question.geographic?
        create_column(code: code, name: [code, 'Latitude'])
        create_column(code: code, name: [code, 'Longitude'])
      end
    else
      create_column(code: code)
    end
  end

  def create_column(code: nil, name: nil)
    name ||= code
    column = ResponseCSV::Column.new(code: code, name: name, position: columns.size)
    columns << column
    columns_by_question[code] ||= []
    columns_by_question[code] << column
  end

  def column_exists_with_code?(code)
    !columns_by_question[code].nil?
  end
end

class ResponseCSV::Column
  include CSVHelper, Comparable
  attr_accessor :code, :name, :position

  def initialize(code: nil, name: nil, position: nil)
    @code = code
    @name = Array.wrap(name).join(":").gsub(/[^a-z0-9:]/i, '')
    @position = position
  end

  def to_s
    format_csv_para_text(name)
  end

  def inspect
    "#{@position}: #{@code} - #{@name}"
  end
end

class ResponseCSV::QA
  include CSVHelper

  def initialize(question, answers)
    @question = question
    @answers = answers
    @answer = answers.first
    @question_type = question.qtype_name
  end

  def cells
    arr = case question_type
    when 'select_one'
      arr = answers.map{ |a| format_csv_para_text(a.option_name) }
      if question.multilevel?
        arr += ([nil] * (question.level_count - arr.size))
      end
      if question.geographic?
        arr += lat_lng(answers.last)
      end
      arr
    when 'location'
      lat_lng(answer)
    when 'datetime'
      [answer.casted_value.try(:to_s, :std_datetime_with_tz)]
    when 'date', 'time'
      [answer.casted_value.try(:to_s, :"std_#{question_type}")]
    else
      [format_csv_para_text(answer.casted_value)]
    end
  end

  private

  attr_accessor :question, :answers, :answer, :question_type

  def lat_lng(ans)
    ans.lat_lng || [nil, nil]
  end
end
