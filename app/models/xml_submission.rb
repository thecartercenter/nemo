class XMLSubmission
  attr_accessor :response, :data

  def initialize(response: nil, files: nil, source: nil, data: nil)
    @response = response
    @response.source = source
    @awaiting_media = @response.awaiting_media
    case source
    when "odk"
      @data = files.delete(:xml_submission_file).read
      @files = files
      populate_from_odk(@data)
    when "j2me"
      @data = data
      @files = files
      populate_from_j2me(@data)
    end
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

  def populate_from_odk(xml)
    data = Nokogiri::XML(xml).root
    lookup_and_check_form(id: data["id"], version: data["version"])
    check_for_existing_response

    if @awaiting_media
      @response.odk_hash = odk_hash
    else
      @response.odk_hash = nil
    end

    # Loop over each child tag and create hash of odk_code => value
    hash = {}
    data.elements.each do |child|
      group = child if child.elements.present?
      if group
        group.elements.each do |c|
          hash[c.name] ||= []
          hash[c.name] << c.try(:content)
        end
      else
        hash[child.name] = child.try(:content)
      end
    end

    populate_from_hash(hash)
  end

  def populate_from_j2me(data)
    lookup_and_check_form(id: data.delete("id"), version: data.delete("version"))

    # Get rid of other unneeded keys.
    data = data.except(*%w(uiVersion name xmlns xmlns:jrm))

    populate_from_hash(data)
  end

  # Populates response given a hash of odk-style question codes (e.g. q5, q7_1) to string values.
  def populate_from_hash(hash)
    # Response mission should already be set
    raise "Submissions must have a mission" if @response.mission.nil?

    @response.form.visible_questionings.each do |qing|
      qing.subqings.each do |subq|
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
