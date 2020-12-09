# frozen_string_literal: true

# Quickly deletes a set of responses.
class ResponseDestroyer < ApplicationDestroyer
  protected

  def do_destroy
    # The destroyer is responsible for checking destroy permissions so we do so here by scoping.
    self.scope = scope.accessible_by(ability, :destroy) if ability.present?
    ids = scope.pluck(:id)
    return if ids.empty?

    Media::Object.joins(:answer).where(answers: {response_id: ids}).delete_all
    Choice.joins(:answer).where(answers: {response_id: ids}).delete_all

    node_scope = ResponseNode.where(response_id: ids)
    node_ids = node_scope.pluck(:id)
    SqlRunner.instance.run("DELETE FROM answer_hierarchies WHERE descendant_id IN (?)", node_ids)
    node_scope.update_all(parent_id: nil)
    node_scope.delete_all

    counts[:destroyed] = Response.where(id: ids).delete_all
  end
end
