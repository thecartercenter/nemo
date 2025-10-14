# frozen_string_literal: true

module Api
  module V1
    class FormsController < BaseController
      before_action :set_form, only: [:show, :update, :destroy]

      def index
        authorize!(:read, Form)
        
        forms = Form.accessible_by(current_ability)
                   .where(mission: current_mission)
                   .includes(:questions, :responses)
        
        # Apply filters
        forms = forms.where(status: params[:status]) if params[:status].present?
        forms = forms.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
        forms = forms.where(smsable: true) if params[:smsable] == 'true'
        
        # Pagination
        forms = forms.paginate(paginate_params)
        
        render json: success_response({
          forms: forms.map { |form| form_json(form) },
          pagination: {
            current_page: forms.current_page,
            total_pages: forms.total_pages,
            total_count: forms.total_entries,
            per_page: forms.per_page
          }
        })
      end

      def show
        authorize!(:read, @form)
        
        render json: success_response(form_json(@form, include_questions: true))
      end

      def create
        authorize!(:create, Form)
        
        form = Form.new(form_params.merge(mission: current_mission))
        
        if form.save
          render json: success_response(form_json(form), 'Form created successfully'), status: :created
        else
          render json: error_response('Failed to create form', form.errors), status: :unprocessable_entity
        end
      end

      def update
        authorize!(:update, @form)
        
        if @form.update(form_params)
          render json: success_response(form_json(@form), 'Form updated successfully')
        else
          render json: error_response('Failed to update form', @form.errors), status: :unprocessable_entity
        end
      end

      def destroy
        authorize!(:destroy, @form)
        
        @form.destroy
        render json: success_response({}, 'Form deleted successfully')
      end

      def publish
        authorize!(:update, @form)
        
        @form.update!(status: 'published', published_changed_at: Time.current)
        
        render json: success_response(form_json(@form), 'Form published successfully')
      end

      def unpublish
        authorize!(:update, @form)
        
        @form.update!(status: 'draft')
        
        render json: success_response(form_json(@form), 'Form unpublished successfully')
      end

      private

      def set_form
        @form = Form.accessible_by(current_ability)
                   .where(mission: current_mission)
                   .find(params[:id])
      end

      def form_params
        params.require(:form).permit(
          :name, :description, :allow_incomplete, :authenticate_sms,
          :smsable, :sms_relay, :access_level
        )
      end

      def form_json(form, include_questions: false)
        data = {
          id: form.id,
          name: form.name,
          description: form.description,
          status: form.status,
          allow_incomplete: form.allow_incomplete,
          authenticate_sms: form.authenticate_sms,
          smsable: form.smsable,
          sms_relay: form.sms_relay,
          access_level: form.access_level,
          response_count: form.responses.count,
          created_at: form.created_at.iso8601,
          updated_at: form.updated_at.iso8601
        }
        
        if include_questions
          data[:questions] = form.questions.map do |question|
            {
              id: question.id,
              code: question.code,
              name: question.name,
              type: question.qtype_name,
              required: question.required?,
              options: question.option_set&.options&.map do |option|
                {
                  id: option.id,
                  name: option.name
                }
              end
            }
          end
        end
        
        data
      end
    end
  end
end