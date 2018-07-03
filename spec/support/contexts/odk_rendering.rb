# odk rendering helper
shared_context "odk rendering" do

  # decorate objects
  def decorate(obj)
    Odk::DecoratorFactory.decorate(obj)
  end
end
