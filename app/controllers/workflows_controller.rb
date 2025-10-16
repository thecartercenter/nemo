# frozen_string_literal: true

class WorkflowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_workflow, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    authorize!(:view, :workflows)
    
    @workflows = Workflow.where(mission: @mission)
                        .includes(:user, :workflow_instances)
                        .order(created_at: :desc)
                        .paginate(page: params[:page], per_page: 20)
  end

  def show
    authorize!(:view, @workflow)
    
    @instances = @workflow.workflow_instances
                          .includes(:trigger_user, :approval_requests)
                          .order(created_at: :desc)
                          .paginate(page: params[:page], per_page: 20)
    
    @stats = {
      total_instances: @instances.total_entries,
      pending: @instances.pending.count,
      completed: @instances.completed.count,
      cancelled: @instances.cancelled.count,
      failed: @instances.failed.count
    }
  end

  def new
    authorize!(:create, :workflow)
    
    @workflow = Workflow.new(mission: @mission, user: current_user)
    @workflow_types = Workflow::WORKFLOW_TYPES
  end

  def create
    authorize!(:create, :workflow)
    
    @workflow = Workflow.new(workflow_params.merge(mission: @mission, user: current_user))
    
    if @workflow.save
      redirect_to workflow_path(@workflow), notice: 'Workflow was successfully created.'
    else
      @workflow_types = Workflow::WORKFLOW_TYPES
      render :new
    end
  end

  def edit
    authorize!(:update, @workflow)
    
    @workflow_types = Workflow::WORKFLOW_TYPES
  end

  def update
    authorize!(:update, @workflow)
    
    if @workflow.update(workflow_params)
      redirect_to workflow_path(@workflow), notice: 'Workflow was successfully updated.'
    else
      @workflow_types = Workflow::WORKFLOW_TYPES
      render :edit
    end
  end

  def destroy
    authorize!(:destroy, @workflow)
    
    @workflow.destroy
    redirect_to workflows_path, notice: 'Workflow was successfully deleted.'
  end

  def activate
    authorize!(:update, @workflow)
    
    @workflow.update!(active: true)
    redirect_to workflow_path(@workflow), notice: 'Workflow activated successfully.'
  end

  def deactivate
    authorize!(:update, @workflow)
    
    @workflow.update!(active: false)
    redirect_to workflow_path(@workflow), notice: 'Workflow deactivated successfully.'
  end

  def create_instance
    @workflow = Workflow.find(params[:id])
    authorize!(:create, :workflow_instance)
    
    trigger_object_type = params[:trigger_object_type]
    trigger_object_id = params[:trigger_object_id]
    allowed_types = ['User', 'Document', 'Task'] # <-- Replace with actual permitted class names
    unless allowed_types.include?(trigger_object_type)
      render json: { success: false, error: 'Invalid trigger_object_type' }, status: :bad_request and return
    end
    trigger_object = trigger_object_type.constantize.find(trigger_object_id)
    
    instance = @workflow.create_instance(trigger_object, current_user)
    
    render json: {
      success: true,
      instance: instance.summary
    }
  end

  def my_approvals
    authorize!(:view, :workflow_instances)
    
    @approval_requests = ApprovalRequest.joins(:workflow_instance)
                                       .where(approver: current_user)
                                       .where(status: 'pending')
                                       .includes(:workflow_instance, :workflow_step)
                                       .order(:due_date)
                                       .paginate(page: params[:page], per_page: 20)
  end

  def my_workflows
    authorize!(:view, :workflow_instances)
    
    @instances = WorkflowInstance.joins(:workflow)
                                .where(workflows: { mission: @mission })
                                .where(trigger_user: current_user)
                                .includes(:workflow, :trigger_object)
                                .order(created_at: :desc)
                                .paginate(page: params[:page], per_page: 20)
  end

  def approve
    @instance = WorkflowInstance.find(params[:instance_id])
    authorize!(:approve, @instance)
    
    comments = params[:comments]
    
    if @instance.approve!(current_user, comments)
      render json: {
        success: true,
        message: 'Approval submitted successfully'
      }
    else
      render json: {
        success: false,
        message: 'Unable to approve this request'
      }, status: 422
    end
  end

  def reject
    @instance = WorkflowInstance.find(params[:instance_id])
    authorize!(:approve, @instance)
    
    reason = params[:reason]
    
    if @instance.reject!(current_user, reason)
      render json: {
        success: true,
        message: 'Request rejected successfully'
      }
    else
      render json: {
        success: false,
        message: 'Unable to reject this request'
      }, status: 422
    end
  end

  def cancel
    @instance = WorkflowInstance.find(params[:instance_id])
    authorize!(:cancel, @instance)
    
    reason = params[:reason]
    
    if @instance.cancel!(current_user, reason)
      render json: {
        success: true,
        message: 'Workflow cancelled successfully'
      }
    else
      render json: {
        success: false,
        message: 'Unable to cancel this workflow'
      }, status: 422
    end
  end

  def instance_details
    @instance = WorkflowInstance.find(params[:instance_id])
    authorize!(:view, @instance)
    
    @logs = @instance.workflow_logs
                     .includes(:user)
                     .order(created_at: :desc)
    
    @approval_requests = @instance.approval_requests
                                 .includes(:approver)
                                 .order(:created_at)
    
    render json: {
      instance: @instance.summary,
      logs: @logs.map(&:summary),
      approval_requests: @approval_requests.map do |req|
        {
          id: req.id,
          approver: req.approver.name,
          status: req.status,
          due_date: req.due_date,
          comments: req.comments,
          urgency: req.urgency_level
        }
      end
    }
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_workflow
    @workflow = Workflow.find(params[:id])
  end

  def workflow_params
    params.require(:workflow).permit(
      :name, :description, :workflow_type, :active,
      config: {}
    )
  end
end