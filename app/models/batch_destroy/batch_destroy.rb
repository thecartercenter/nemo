# frozen_string_literal: true
module BatchDestroy
  # Abstract batch destroy objects in batches
  class BatchDestroy
    attr_reader :rel, :ability

    def initialize(params)
      @rel = params[:rel]
      @ability = params[:ability]
      @skipped = []
    end

    def destroy!
      deactivated = []
      destroyed = []

      begin
        ActiveRecord::Base.transaction do
          @rel.each do |object|
            next if object == @skipped.first

            begin
              raise DeletionError unless @ability.can?(:destroy, object)

              object.destroy
              destroyed << object
            rescue DeletionError
              if object.try(:active?)
                object.activate!(false)
                deactivated << object
              else
                @skipped << object
              end
            end
          end
        end
      end

      # return counts for destroyed, skipped and deactivated objects
      {destroyed: destroyed.count, skipped: @skipped.count, deactivated: deactivated.count}
    end
  end
end
