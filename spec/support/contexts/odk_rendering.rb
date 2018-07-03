# frozen_string_literal: true

shared_context "odk rendering" do
  def decorate(obj)
    Odk::DecoratorFactory.decorate(obj)
  end
end
