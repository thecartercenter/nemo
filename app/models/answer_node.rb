# Models a group of answers in a single repeat-instance of a single FormItem
# (either group or individual question) on a single response.
# See AnswerArranger for more documentation.
class AnswerNode
  attr_accessor :item, :instances, :placeholder_instance, :set

  delegate :repeatable?, to: :item

  def initialize(params)
    self.item = params[:item]
    self.instances = []
    self.set = params[:set]
  end
end
