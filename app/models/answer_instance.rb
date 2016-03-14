# A set of AnswerNodes corresponding to one repeat instance of a QingGroup.
# See AnswerNodeBuilder for more documentation.
class AnswerInstance
  attr_accessor :nodes

  def initialize(params)
    self.nodes = params[:nodes]
  end
end
