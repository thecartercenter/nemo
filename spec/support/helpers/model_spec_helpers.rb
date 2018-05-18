module ModelSpecHelpers
  def create_report(klass, options)
    # handle option_set parameter
    if option_set = options.delete(:option_set)
      options[:option_set_choices_attributes] = [{option_set_id: option_set.id}]
    end

    # this is no longer the default
    options[:question_labels] ||= 'code'

    report = "Report::#{klass}Report".constantize.new(mission_id: get_mission.id)
    report.generate_default_name
    report.update_attributes!({name: "TheReport"}.merge(options))
    report
  end

  def expect_location_answer(answer, params)
    answer.save
    # If the answer is invalid there is no need to check if values were copied correctly.
    return if answer.invalid?

    answer.reload
    expect(answer.value).to eq params[:val]
    {lat: :latitude, lng: :longitude, alt: :altitude, acc: :accuracy}.each do |k, v|
      if params[k].nil?
        expect(answer[v]).to be_nil
      else
        expect(answer[v]).to be_within(0.00001).of(params[k])
      end
    end
  end
end
