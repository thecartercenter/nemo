# frozen_string_literal: true

class WebhooksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_webhook, only: %i[show edit update destroy test deliveries]

  def index
    authorize!(:manage, :webhooks)

    @webhooks = Webhook.where(mission: @mission)
      .includes(:webhook_deliveries)
      .order(created_at: :desc)
      .paginate(page: params[:page], per_page: 20)
  end

  def show
    authorize!(:manage, :webhooks)

    @recent_deliveries = @webhook.recent_deliveries(20)
    @delivery_stats = {
      total: @webhook.webhook_deliveries.count,
      successful: @webhook.webhook_deliveries.successful.count,
      failed: @webhook.webhook_deliveries.failed.count,
      success_rate: @webhook.success_rate
    }
  end

  def new
    authorize!(:manage, :webhooks)

    @webhook = Webhook.new(mission: @mission)
    @available_events = Webhook::WEBHOOK_EVENTS
  end

  def edit
    authorize!(:manage, :webhooks)

    @available_events = Webhook::WEBHOOK_EVENTS
  end

  def create
    authorize!(:manage, :webhooks)

    @webhook = Webhook.new(webhook_params.merge(mission: @mission))

    if @webhook.save
      redirect_to(webhook_path(@webhook), notice: "Webhook was successfully created.")
    else
      @available_events = Webhook::WEBHOOK_EVENTS
      render(:new)
    end
  end

  def update
    authorize!(:manage, :webhooks)

    if @webhook.update(webhook_params)
      redirect_to(webhook_path(@webhook), notice: "Webhook was successfully updated.")
    else
      @available_events = Webhook::WEBHOOK_EVENTS
      render(:edit)
    end
  end

  def destroy
    authorize!(:manage, :webhooks)

    @webhook.destroy
    redirect_to(webhooks_path, notice: "Webhook was successfully deleted.")
  end

  def test
    authorize!(:manage, :webhooks)

    @webhook.test_webhook
    redirect_to(webhook_path(@webhook), notice: "Test webhook triggered successfully.")
  end

  def deliveries
    authorize!(:manage, :webhooks)

    @deliveries = @webhook.webhook_deliveries
      .includes(:webhook)
      .order(created_at: :desc)
      .paginate(page: params[:page], per_page: 20)
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_webhook
    @webhook = Webhook.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:name, :url, :secret, :active, events: [])
  end
end
