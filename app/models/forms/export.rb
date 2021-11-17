# frozen_string_literal: true

module Forms
  # Exports a form to a human readable format for science
  class Export
    def initialize(form)
      @form = form
      @columns = %w[Level Type ID Code Prompt Logic]
    end

    def to_csv
      CSV.generate(**options) do |csv|
        csv << @columns

        
    end


  end

end
