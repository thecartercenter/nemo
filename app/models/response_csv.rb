class ResponseCSV
  include CSVHelper
  attr_accessor :csv, :responses

  def initialize(responses, row_sep: "\r\n", locale: 'en')
    @responses = responses
    @row_sep = row_sep
    @columns = []
    @columns_by_question = {}
    @csv = generate_csv
  end

  def to_s
    @csv
  end

  private

  def generate_csv
    # We use \r\n because Excel seems to prefer it.
    CSV.generate(row_sep: @row_sep) do |csv|
      @processed_forms = []
      @rows = []

      create_column code: "Form"
      create_column code: "Submitter"
      create_column code: "DateSubmitted"
      create_column code: "ResponseID"

      @responses.each do |response|
        process_form(response.form) unless @processed_forms.include?(response.form_id)
        row = [response.form.name, response.user.name, response.created_at, response.id]
        questions = response.answers.group_by(&:question)
        questions.each do |question, answers|
          columns = @columns_by_question[question.code]
          qa = ResponseCSV::QA.new(question, answers)
          columns.each_with_index do |c, i|
            row[c.position] = qa.cells[i]
          end
        end
        @rows << row
      end

      csv << @columns
      @rows.each do |row|
        csv << row
      end
    end
  end

  def process_form(form)
    form.questions.each do |question|
      create_column question: question
    end
    @processed_forms << form.id
  end

  def create_column(code: nil, question: nil)
    code ||= question.code
    @columns_by_question[code] = []
    if question && (question.multi_level? || question.geographic?)
      if question.multi_level?
        question.levels.each_with_index do |level, i|
          column = ResponseCSV::Column.new(code: code, name: [code, level.name], question: question, position: @columns.size)
          @columns << column unless @columns.include?(column)
          @columns_by_question[code] << column
        end
      end
      if question.geographic?
        lat = ResponseCSV::Column.new(code: code, name: [code, 'Latitude'], question: question, position: @columns.size)
        @columns << lat unless @columns.include?(lat)
        lng = ResponseCSV::Column.new(code: code, name: [code, 'Longitude'], question: question, position: @columns.size)
        @columns << lng unless @columns.include?(lng)
        @columns_by_question[code] << lat << lng
      end
    else
      column = ResponseCSV::Column.new(code: code, name: code.to_s, question: question, position: @columns.size)
      @columns << column unless @columns.include?(column)
      @columns_by_question[code] << column
    end
  end
end

class ResponseCSV::Column
  include CSVHelper, Comparable
  attr_accessor :code, :name, :position

  def initialize(code: nil, name: nil, question: nil, position: nil)
    @code = code || question.code
    @name = Array.wrap(name).join(":").gsub(/[^a-z0-9:]/i, '')
    @question = question
    @position = position
  end

  def to_s
    format_csv_para_text(name)
  end

  def inspect
    "#{@position}: #{@code} - #{@name}"
  end

  def <=>(other)
    self.name <=> other.name
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
    arr = case @question_type
    when 'select_one'
      arr = @answers.map{ |a| format_csv_para_text(a.option_name) }
      if @question.multi_level?
        arr += ([nil] * (@question.level_count - arr.size))
      end
      if @question.geographic?
        arr += lat_lng(@answers.last)
      end
      arr
    when 'location'
      lat_lng(@answer)
    else
      [format_csv_para_text(@answer.formatted_value)]
    end
  end

  private

  def lat_lng(ans)
    ans.lat_lng || [nil, nil]
  end
end
