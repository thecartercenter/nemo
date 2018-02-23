# frozen_string_literal: true

# Removes the annoying field_with_errors wrapper from label tags.
# From https://stackoverflow.com/a/5268106/2066866
ActionView::Base.field_error_proc = proc { |html_tag, _| html_tag }
