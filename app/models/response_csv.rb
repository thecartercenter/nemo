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

      create_column code: :form, name: I18n.t('attrib_fields.form')
      create_column code: :submitter, name: I18n.t('attrib_fields.submitter')
      create_column code: :date_submitted, name: I18n.t('attrib_fields.date_submitted')
      create_column code: :response_id, name: I18n.t('attrib_fields.response_id')

      @responses.each do |response|
        process_form(response.form) unless @processed_forms.include?(response.form_id)
        row = [response.form.name, response.user.name, response.created_at, response.id]
        questions = response.answers.group_by(&:question)
        questions.each do |question, answers|
          answers.each do |answer|
            columns = @columns_by_question[[question.code, answer.rank]]
            qa = ResponseCSV::QA.new(question, answer)
            columns.each_with_index do |c, i|
              row[c.position] = qa.cells[i]
            end
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

  def create_column(code: nil, name: nil, question: nil)
    code ||= question.code
    multi_level = question.multi_level? if question
    geographic = (question.qtype_name == 'location' || question.geographic?) if question
    if question && (multi_level || geographic)
      if multi_level
        question.levels.each_with_index do |level, i|
          column = ResponseCSV::Column.new(code: code, name: [code, level.name].join(':'), question: question, position: @columns.size)
          @columns << column unless @columns.include?(column)
          @columns_by_question[[code, i+1]] ||= []
          @columns_by_question[[code, i+1]] << column
        end
      end
      if geographic
        lat = ResponseCSV::Column.new(code: code, name: [code, 'Latitude'].join(':'), question: question, position: @columns.size)
        @columns << lat unless @columns.include?(lat)
        lng = ResponseCSV::Column.new(code: code, name: [code, 'Longitude'].join(':'), question: question, position: @columns.size)
        @columns << lng unless @columns.include?(lng)
        @columns_by_question[[code, nil]] ||= [lat, lng]
      end
    else
      column = ResponseCSV::Column.new(code: code, name: code.to_s, question: question, position: @columns.size)
      @columns << column unless @columns.include?(column)
      @columns_by_question[[code, nil]] ||= [column]
    end
  end
end

class ResponseCSV::Column
  include CSVHelper, Comparable
  attr_accessor :code, :name, :position

  def initialize(code: nil, name: nil, question: nil, position: nil)
    @code = code || question.code
    @name = name.titleize.gsub(/[^a-z0-9:]/i, '')
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
  def initialize(question, answer)
    @question = question
    @answer = answer
    @question_type = question.qtype_name
  end

  def cells
    case @question_type
    when 'location' || @question.geographic?
      [@answer.latitude.to_s, @answer.longitude.to_s]
    else
      [to_s]
    end
  end

  def to_s
    case @question_type
    when 'long_text', 'text', 'integer', @answer.value.present?
      format_csv_para_text(@answer.value) || ''
    when 'select_one'
      if @answer.option
        format_csv_para_text(@answer.option.name)
      else
        ''
      end
    when 'time', 'datetime'
      time = @answer.date_value || @answer.time_value || @answer.datetime_value
      time ? I18n.l(time) : ''
    when 'select_multiple'
      choices = @answer.choices.map(&:option).map(&:name).join(';')
      format_csv_para_text(choices)
    else
      @answer.inspect || ''
    end
  end
end
