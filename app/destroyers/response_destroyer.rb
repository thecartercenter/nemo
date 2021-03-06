# frozen_string_literal: true

# Quickly deletes a set of responses.
class ResponseDestroyer < ApplicationDestroyer
  protected

  def do_destroy
    # The destroyer is responsible for checking destroy permissions so we do so here by scoping.
    self.scope = scope.accessible_by(ability, :destroy) if ability.present?
    ids = scope.pluck(:id)
    return if ids.empty?

    delete_associations(ids)
    delete_nodes(ids)
    counts[:destroyed] = Response.where(id: ids).delete_all
  end

  def delete_associations(ids)
    Media::Object.joins(:answer).where(answers: {response_id: ids}).delete_all
    Choice.joins(:answer).where(answers: {response_id: ids}).delete_all
  end

  def delete_nodes(response_ids)
    node_scope = ResponseNode.where(response_id: response_ids)

    # Divide the responses evenly across all CPUs.
    # Note: Setting NUM_PROCS=1 will effectively make this a synchronous operation.
    num_procs = ENV["NUM_PROCS"].presence&.to_i || Etc.nprocessors
    page_size = (1.0 * node_scope.count / num_procs).ceil

    id_chunks = (1..num_procs).map do |page_num|
      offset = (page_num - 1) * page_size
      node_chunk = node_scope.limit(page_size).offset(offset)
      node_chunk.pluck(:id)
    end
    # For small jobs on large machines, we may not need all CPUs.
    id_chunks = id_chunks.filter(&:present?)

    Rails.logger.debug("\n@@@ Chunks: #{id_chunks}\n")

    # rubocop:disable Style/CombinableLoops
    Parallel.each(id_chunks, in_processes: num_procs, isolation: true) do |id_chunk|
      SqlRunner.instance.run("DELETE FROM answer_hierarchies WHERE descendant_id IN (?)", id_chunk)
    end

    sleep(1)
    Parallel.each(id_chunks, in_processes: num_procs, isolation: true) do |id_chunk|
      ResponseNode.where(id: id_chunk).update_all(parent_id: nil)
    end

    sleep(1)
    Parallel.each(id_chunks, in_processes: num_procs, isolation: true) do |id_chunk|
      ResponseNode.where(id: id_chunk).delete_all
    end
    # rubocop:enable Style/CombinableLoops

    # Parallel.each(id_chunks, in_processes: num_procs, isolation: true) do |id_chunk|
    #   Rails.logger.debug("\n@@@ Will delete count #{id_chunk.count} (#{id_chunk.pluck(:id)})\n")
    #   delete_node_page(id_chunk)
    # end
  end

  # Parallel-safe method (given IDs, not ActiveStorage relations)
  def delete_node_page(node_ids)
    SqlRunner.instance.run("DELETE FROM answer_hierarchies WHERE descendant_id IN (?)", node_ids)

    # TODO: This update operation is particularly slow.
    # SqlRunner.instance.run("UPDATE answers SET parent_id = NULL WHERE answers.response_id IN (?)", node_ids)
    # SqlRunner.instance.run("DELETE FROM answers WHERE answers.response_id IN (?)", node_ids)

    node_scope = ResponseNode.where(id: node_ids)
    Rails.logger.debug("\n@@@ xDeleting count #{node_scope.count} (#{node_ids})\n")
    node_scope.update_all(parent_id: nil)
    node_scope.delete_all
  end
end
