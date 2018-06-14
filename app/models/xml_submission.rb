class XMLSubmission
  attr_accessor :response, :data

  def initialize(response: nil, files: nil)
    @response = response
    @awaiting_media = @response.awaiting_media
    # We allow passing data via string in case we need to reprocess xml.
    @data = files.delete(:xml_submission_file).read
    @files = files
    @response.source = "odk" # only kind of source we expect and can process
    populate_from_odk(@data)
  end

  def save
    # We save XML submissions without validating, as we have no way to present validation errors to user,
    # and submitting apps already do validation.
    @response.save(validate: false)
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

  def populate_from_odk(xml)
    data = Nokogiri::XML(xml).root
    lookup_and_check_form(id: data["id"], version: data["version"])
    check_for_existing_response
    @response.odk_xml = xml

    if @awaiting_media
      @response.odk_hash = odk_hash
    else
      @response.odk_hash = nil
    end

    # Response mission should already be set
    raise "Submissions must have a mission" if @response.mission.nil?

    # Loop over each child tag and create hash of odk_code => value
    hash = {}
    data.elements.each do |child|
      # If child is a group
      if child.elements.present?
        hash[child.name] ||= [] # Each element in the array is an instance.
        instance = {}
        child.elements.each do |c|
          instance[c.name] = c.content
        end
        hash[child.name] << instance
      else
        hash[child.name] = child.content
      end
    end

    populate_from_hash(hash)
  end

  # Populates response given a hash of odk-style question codes (e.g. q5, q7_1) to string values.
  def populate_from_hash(hash)
    # Response mission should already be set
    raise "Submissions must have a mission" if @response.mission.nil?

    Odk::DecoratorFactory.decorate_collection(@response.form.children).each do |item|
      if item.group?
        (hash[item.odk_code] || []).each_with_index do |instance, inst_num|
          item.children.each do |qing|
            add_answers_for_qing(Odk::DecoratorFactory.decorate(qing), instance, inst_num + 1)
          end
        end
      else
        add_answers_for_qing(item, hash, 1)
      end
    end
    @response.incomplete ||= (hash[Odk::FormDecorator::IR_QUESTION] == "yes")
  end

  def add_answers_for_qing(qing, hash, inst_num)
    qing.subqings.each do |subq|
      value = hash[subq.odk_code]
      # QUESTION: why is answer reassigned? it tries both? why?
      answer = fetch_or_build_answer(questioning: qing.object, rank: subq.rank, inst_num: inst_num)
      answer = populate_from_string(answer, value)
      @response.answers << answer if answer
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
      # Time answers arrive with timezone info (e.g. 18:30:00.000-04), but we treat a time question
      # as having no timezone, useful for things like 'what time of day does the doctor usually arrive'
      # as opposed to 'what exact date/time did the doctor last arrive'.
      # If the latter information is desired, a datetime question should be used.
      # Also, since Rails treats time data as always on 2000-01-01, using the timezone
      # information could lead to DST issues. So we discard the timezone information for time questions only.
      # We also make sure elsewhere in the app to not tz-shift time answers when we display them.
      # (Rails by default keeps time columns as UTC and does not shift them to the system's timezone.)
      if answer.qtype.name == "time"
        puts str
        str = str.gsub(/(Z|[+\-]\d+(:\d+)?)$/, "") << " UTC"
        puts str
      end
      answer.send("#{question_type.name}_value=", Time.zone.parse(str))
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
    if id_or_str =~ /\Aon([\w\-]+)\z/
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
