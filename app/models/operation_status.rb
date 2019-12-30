# frozen_string_literal: true

class OperationStatus
  attr_reader :total, :started, :failed, :completed, :in_progress

  def initialize(operations)
    sql = operations.select(
      "count(1) as total",
      "count(operations.job_started_at) as started",
      "count(operations.job_failed_at) as failed",
      "count(operations.job_completed_at) as completed"
    ).to_sql

    @total, @started, @failed, @completed = SqlRunner.instance.run(sql).first.values
    @in_progress = @total - @completed
  end

  # define a prop? method for each value checking if it's > 0
  %i[total started failed completed in_progress].each do |sym|
    define_method("#{sym}?", -> { send(sym).positive? })
  end
end
