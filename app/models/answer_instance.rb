# A set of AnswerNodes corresponding to one repeat instance of a QingGroup.
# See AnswerNodeBuilder for more documentation.
class AnswerInstance
  attr_accessor :nodes, :num

  def initialize(params)
    self.num = params[:num]
    self.nodes = params[:nodes]
  end
end
