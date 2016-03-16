# A set of AnswerNodes corresponding to one repeat instance of a QingGroup.
# See AnswerArranger for more documentation.
class AnswerInstance
  attr_accessor :nodes, :num, :blank
  alias_method :blank?, :blank

  def initialize(params)
    self.num = params[:num]
    self.nodes = params[:nodes]
    self.blank = params[:blank] || false

    if blank?
      self.num = "__INST_NUM__" # Used as placeholder
    end
  end
end
