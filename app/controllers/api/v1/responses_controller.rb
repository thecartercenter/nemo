# frozen_string_literal: true

module Api
  module V1
    class ResponsesController < BaseController
      before_action :set_response, only: %i[show update destroy]

      # Whitelists for allowed order columns and directions
      ORDER_COLUMNS = %w[created_at form_id user_id reviewed incomplete source].freeze
      ORDER_DIRECTIONS = %w[asc desc].freeze

      def index
        authorize!(:read, Response)

        responses = Response.accessible_by(current_ability)
          .where(mission: current_mission)
          .includes(:form, :user, :answers)

        # Apply filters
        responses = responses.where(form_id: params[:form_id]) if params[:form_id].present?
        responses = responses.where(user_id: params[:user_id]) if params[:user_id].present?
        responses = responses.where(source: params[:source]) if params[:source].present?
        responses = responses.where(incomplete: params[:incomplete]) if params[:incomplete].present?
        responses = responses.where(reviewed: params[:reviewed]) if params[:reviewed].present?

        # Date filters
        if params[:date_from].present?
          responses = responses.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
        end
        if params[:date_to].present?
          responses = responses.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
        end

        # Ordering
        order = ORDER_COLUMNS.include?(params[:order]) ? params[:order] : "created_at"
        direction = ORDER_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "desc"
        responses = responses.order(order => direction)

        # Pagination
        responses = responses.paginate(paginate_params)

        render(json: success_response({
          responses: responses.map { |response| response_json(response) },
          pagination: {
            current_page: responses.current_page,
            total_pages: responses.total_pages,
            total_count: responses.total_entries,
            per_page: responses.per_page
          }
        }))
      end

      def show
        authorize!(:read, @response)

        render(json: success_response(response_json(@response, include_answers: true)))
      end

      def create
        authorize!(:create, Response)

        response = Response.new(response_params.merge(
          mission: current_mission,
          user: current_user,
          source: "api"
        ))

        if response.save
          # Process answers if provided
          process_answers(response, params[:answers]) if params[:answers].present?

          render(json: success_response(response_json(response), "Response created successfully"), status: :created)
        else
          render(json: error_response("Failed to create response", response.errors), status: :unprocessable_entity)
        end
      end

      def update
        authorize!(:update, @response)

        if @response.update(response_params)
          # Process answers if provided
          process_answers(@response, params[:answers]) if params[:answers].present?

          render(json: success_response(response_json(@response), "Response updated successfully"))
        else
          render(json: error_response("Failed to update response", @response.errors), status: :unprocessable_entity)
        end
      end

      def destroy
        authorize!(:destroy, @response)

        @response.destroy
        render(json: success_response({}, "Response deleted successfully"))
      end

      def submit
        authorize!(:update, @response)

        @response.update!(incomplete: false)

        render(json: success_response(response_json(@response), "Response submitted successfully"))
      end

      def mark_incomplete
        authorize!(:update, @response)

        @response.update!(incomplete: true)

        render(json: success_response(response_json(@response), "Response marked as incomplete"))
      end

      private

      def set_response
        @response = Response.accessible_by(current_ability)
          .where(mission: current_mission)
          .find(params[:id])
      end

      def response_params
        params.require(:response).permit(
          :form_id, :incomplete, :reviewer_notes, :device_id
        )
      end

      def process_answers(response, answers_data)
        answers_data.each do |answer_data|
          question = Question.find(answer_data[:question_id])
          questioning = Questioning.find_by(form: response.form, question: question)

          next unless questioning

          answer = response.answers.find_or_initialize_by(questioning: questioning)
          answer.value = answer_data[:value]
          answer.save!
        end
      end

      def response_json(response, include_answers: false)
        data = {
          id: response.id,
          shortcode: response.shortcode,
          form: {
            id: response.form.id,
            name: response.form.name
          },
          user: {
            id: response.user.id,
            name: response.user.name
          },
          source: response.source,
          incomplete: response.incomplete?,
          reviewed: response.reviewed?,
          reviewer_notes: response.reviewer_notes,
          device_id: response.device_id,
          created_at: response.created_at.iso8601,
          updated_at: response.updated_at.iso8601
        }

        if include_answers
          data[:answers] = response.answers.map do |answer|
            {
              id: answer.id,
              question: {
                id: answer.questioning.question.id,
                code: answer.questioning.question.code,
                name: answer.questioning.question.name,
                type: answer.questioning.question.qtype_name
              },
              value: answer.value,
              created_at: answer.created_at.iso8601,
              updated_at: answer.updated_at.iso8601
            }
          end
        end

        data
      end
    end
  end
end
