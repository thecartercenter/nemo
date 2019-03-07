# frozen_string_literal: true

class OperationDecorator < ApplicationDecorator
  delegate_all

  def default_path
    @default_path ||= h.operation_path(object)
  end
end
