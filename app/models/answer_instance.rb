# A set of AnswerNodes corresponding to one repeat instance of a QingGroup.
# See AnswerArranger for more documentation.
class AnswerInstance
  attr_accessor :nodes, :num, :placeholder
  alias_method :placeholder?, :placeholder

  def initialize(params)
    self.num = params[:num]
    self.nodes = params[:nodes]
    self.placeholder = params[:placeholder] || false

    if placeholder?
      self.num = "__INST_NUM__" # Used as placeholder
    end
  end
end
