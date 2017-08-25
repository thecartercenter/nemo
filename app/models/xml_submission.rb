class XMLSubmission #TODO: rename to Submission and move to odk namespace
  attr_accessor :response, :data

  def initialize(response: nil, files: nil)
    @response = response
    @awaiting_media = @response.awaiting_media
    @data = files.delete(:xml_submission_file).read
    @files = files
    @response.source = "odk" #this is only kind we expect an can process
    populate_from_odk(@data)
  end

  def save(validate: true)
    @response.save(validate: validate)
  end

  private

  # Checks if form ID and version were given, if form exists, and if version is correct
  def lookup_and_check_form(params)
    # if either of these is nil or not an integer, error
    raise SubmissionError.new("no form id was given") if params[:id].nil?
    raise FormVersionError.new("form version must be specified") if params[:version].nil?

    # try to load form (will raise activerecord error if not found)
    # if the response already has a form, don't fetch it again
    @response.form = Form.find(params[:id]) unless @response.form.present?
    form = @response.form

    # if form has no version, error
    raise "xml submissions must be to versioned forms" if form.current_version.nil?

    # if form version is outdated, error
    raise FormVersionError.new("form version is outdated") if form.current_version.code != params[:version]
  end

  # def wrapper(data)
  # end
  #
  # def recurse(node, form_item)
  #   if node.no_children
  #     if node.is a question
  #       form = @response.form
  #       odk_code = node.name
  #       find what is needed to make answer (qing, subq, rank, instance number?)
  #       make answer
  #       add answer to @response
  #       # are multipart questions different?
  #     end
  #   else
  #     node.children.each
  #       find form item matching this child
  #       recurse (child, appropriate form item)
  #     end
  #   end
  # end

  def simple_recursive(node, hash)
    if node.elements.empty?
      hash[node.name] ||=[]
      value = node.try(:content)
      puts "#{node.name}: #{value}"
      hash[node.name] << node.try(:content)
    else
      node.elements.each do |c|
        simple_recursive(c, hash)
      end
    end
  end

  def populate_from_odk(xml)
    data = Nokogiri::XML(xml).root
    lookup_and_check_form(id: data["id"], version: data["version"])
    check_for_existing_response

    if @awaiting_media
      @response.odk_hash = odk_hash
    else
      @response.odk_hash = nil
    end

    # TODO: make recursive, walk xml tree
    # Loop over each child tag and create hash of odk_code => value
    hash = {}
    simple_recursive(data, hash)
    puts "Hash:"
    puts hash
    populate_from_hash(hash)
  end

  # Populates response given a hash of odk-style question codes (e.g. q5, q7_1) to string values.
  def populate_from_hash(hash)
    # Response mission should already be set
    raise "Submissions must have a mission" if @response.mission.nil?
    puts "#{@response.form.visible_questionings.count} questionings"
    @response.form.visible_questionings.each do |qing|
      qing.subquestions.each do |subq|
        value = hash[subq.odk_code]
        if value.is_a? Array
          value.each_with_index do |val, i|
            answer = fetch_or_build_answer(questioning: qing, rank: subq.rank, inst_num: i + 1)
            answer = populate_from_string(answer, val)
            @response.answers << answer if answer
          end
        else
          answer = fetch_or_build_answer(questioning: qing, rank: subq.rank)
          answer = populate_from_string(answer, value)
          @response.answers << answer if answer
        end
      end
    end
    @response.incomplete ||= (hash[OdkHelper::IR_QUESTION] == "yes")
    puts "Answers: "
    puts @response.answers.count
    @response.answers.map do |a|
      puts "Q#{a.questioning.question_id} instance #{a.inst_num}"
      puts a.value

    end
  end

  # Populates answer from odk-like string value.
  def populate_from_string(answer, str)
    return answer if str.nil?

    question_type = answer.qtype

    case question_type.name
    when "select_one"
      # 'none' will be returned for a blank choice for a multilevel set.
      answer.option_id = option_id_for_submission(str) unless str == "none"
    when "select_multiple"
      str.split(" ").each { |oid| answer.choices.build(option_id: option_id_for_submission(oid)) }
    when "date", "datetime", "time"
      # Strip timezone info for datetime and time.
      str.gsub!(/(Z|[+\-]\d+(:\d+)?)$/, "") unless answer.qtype.name == "date"

      val = Time.zone.parse(str)

      # Not sure why this is here. Investigate later.
      # val = val.to_s(:"db_#{qtype.name}") unless qtype.has_timezone?

      answer.send("#{question_type.name}_value=", val)
    when "image", "annotated_image", "sketch", "signature"
      answer.media_object = Media::Image.create(item: @files[str].open) if @files[str]
    when "audio"
      answer.media_object = Media::Audio.create(item: @files[str].open) if @files[str]
    when "video"
      answer.media_object = Media::Video.create(item: @files[str].open) if @files[str]
    else
      answer.value = str
    end
    # nullify answers if string suggests multimedia answer but no file present to make multi-chunk submissions work
    return nil if (question_type.multimedia? && answer.media_object.blank?)
    answer
  end

  # finds the appropriate Option instance for an ODK submission
  def option_id_for_submission(id_or_str)
    if id_or_str =~ /\Aon(\d+)\z/
      # look up inputs of the form "on####" as option node ids
      OptionNode.id_to_option_id($1)
    else
      # look up other inputs as option ids
      Option.where(id: id_or_str).pluck(:id).first
    end
  end

  # Generates and saves a hash of the complete XML so that multi-chunk media form submissions
  # can be uniquely identified and handled
  def odk_hash
    @odk_hash ||= Digest::SHA256.base64digest @data
  end

  def check_for_existing_response
    response = Response.find_by(odk_hash: odk_hash, form_id: @response.form_id)
    @existing_response = response.present?
    @response = response if @existing_response
  end

  def fetch_or_build_answer(answer_params)
    if @existing_response
      Answer.find_or_initialize_by(answer_params)
    else
      Answer.new(answer_params)
    end
  end
end
