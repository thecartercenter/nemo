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

  def expect_location_answer(params)
    # Note that we test this with validate: false since we don't always run answer
    # validations, but we should be doing this anyway.
    answer.save(validate: false)
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
