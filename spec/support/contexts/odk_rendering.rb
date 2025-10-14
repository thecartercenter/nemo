# frozen_string_literal: true

shared_context "odk rendering" do
  delegate :decorate, to: :"ODK::DecoratorFactory"
end
