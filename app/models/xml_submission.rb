class XMLSubmission
  attr_accessor :response, :data

  def initialize(response: nil, data: nil, source: nil)
    @response = response
    @data = data
    @response.source = source
    case source
    when 'odk'
      populate_from_odk(@data)
    when 'j2me'
      populate_from_j2me(@data)
    end
  end

  private
  # Checks if form ID and version were given, if form exists, and if version is correct
  def lookup_and_check_form(params)
    # if either of these is nil or not an integer, error
    raise SubmissionError.new("no form id was given") if params[:id].nil?
    raise FormVersionError.new("form version must be specified") if params[:version].nil?

    # try to load form (will raise activerecord error if not found)
    @response.form = Form.find(params[:id])
    form = @response.form

    # if form has no version, error
    raise "xml submissions must be to versioned forms" if form.current_version.nil?

    # if form version is outdated, error
    raise FormVersionError.new("form version is outdated") if form.current_version.sequence > params[:version].to_i
  end

  def populate_from_odk(xml)
    data = Nokogiri::XML(xml).root

    lookup_and_check_form(:id => data['id'], :version => data['version'])

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

    @response.populate_from_hash(hash)
  end

  def populate_from_j2me(data)
    lookup_and_check_form(:id => data.delete('id'), :version => data.delete('version'))

    # Get rid of other unneeded keys.
    data = data.except(*%w(uiVersion name xmlns xmlns:jrm))

    @response.populate_from_hash(data)
  end
end
