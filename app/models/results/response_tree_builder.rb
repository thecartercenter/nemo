class Results::ResponseTreeBuilder

  def initialize(form)
    @form = form
  end

  def build
    @rn = ResponseNode.new
    add_children
    @rn
  end

  def add_children
    @form.sorted_children.count.times do
      @rn.children << Answer.new
    end
  end

end
