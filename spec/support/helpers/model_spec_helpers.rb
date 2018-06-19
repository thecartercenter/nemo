module ModelSpecHelpers
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
