# frozen_string_literal: true

# Parent decorator for FormItems
class FormItemDecorator < ApplicationDecorator
  delegate_all

  # Non-deduped, non-unique, non-sorted list of all qings referred to by display conditions.
  def refd_qings
    display_conditions.flat_map(&:refd_qings)
  end
end
