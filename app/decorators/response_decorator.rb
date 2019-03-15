# frozen_string_literal: true

class ResponseDecorator < ApplicationDecorator
  delegate_all

  def shortcode
    model.shortcode&.upcase
  end

  # Gets the answer to the given question on the response.
  def answer_for(question)
    context[:answer_finder].find(self, question)
  end

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    return @default_path if defined?(@default_path)
    path_params = if h.params[:search].present? && !h.flash.now[:search_error]
                    {search: h.params[:search]}
                  else
                    {}
                  end
    @default_path = h.response_path(object, path_params)
  end

  def reviewed_status
    if reviewed?
      h.icon_tag("check") << reviewer_name
    elsif checked_out_at.present? && (checked_out_at > Response::LOCK_OUT_TIME.ago)
      I18n.t("common.pending")
    end
  end

  def reviewer_name
    if reviewed? && reviewer.present?
      h.can?(:read, reviewer) ? h.link_to(reviewer.name, reviewer) : reviewer.name
    else
      ""
    end
  end
end
