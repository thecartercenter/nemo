# frozen_string_literal: true

class BroadcastDecorator < ApplicationDecorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def default_path
    @default_path ||= h.broadcast_path(object)
  end
end
