# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_response
  before_action :set_comment, only: %i[show edit update destroy resolve unresolve]

  def index
    authorize!(:view, @response)

    @comments = @response.comments.includes(:author, :replies, :mentioned_users)
      .top_level
      .recent
      .paginate(page: params[:page], per_page: 20)

    @comment_types = Comment::COMMENT_TYPES
  end

  def show
    authorize!(:view, @response)
  end

  def new
    authorize!(:create, :comment)
    @comment = @response.comments.build(author: current_user)
    @comment_types = Comment::COMMENT_TYPES
  end

  def edit
    authorize!(:update, @comment)
  end

  def create
    authorize!(:create, :comment)

    @comment = @response.comments.build(comment_params.merge(author: current_user))

    if @comment.save
      # Notify response owner and other commenters
      notify_comment_created

      respond_to do |format|
        format.html { redirect_to(response_path(@response), notice: "Comment added successfully.") }
        format.json { render(json: @comment, status: :created) }
      end
    else
      @comment_types = Comment::COMMENT_TYPES
      respond_to do |format|
        format.html { render(:new) }
        format.json { render(json: {errors: @comment.errors}, status: :unprocessable_entity) }
      end
    end
  end

  def update
    authorize!(:update, @comment)

    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to(response_path(@response), notice: "Comment updated successfully.") }
        format.json { render(json: @comment) }
      end
    else
      respond_to do |format|
        format.html { render(:edit) }
        format.json { render(json: {errors: @comment.errors}, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    authorize!(:destroy, @comment)

    @comment.destroy
    respond_to do |format|
      format.html { redirect_to(response_path(@response), notice: "Comment deleted successfully.") }
      format.json { head(:no_content) }
    end
  end

  def resolve
    authorize!(:update, @comment)

    @comment.resolve!
    respond_to do |format|
      format.html { redirect_to(response_path(@response), notice: "Comment resolved.") }
      format.json { render(json: @comment) }
    end
  end

  def unresolve
    authorize!(:update, @comment)

    @comment.unresolve!
    respond_to do |format|
      format.html { redirect_to(response_path(@response), notice: "Comment unresolved.") }
      format.json { render(json: @comment) }
    end
  end

  private

  def set_response
    @response = Response.accessible_by(current_ability).find(params[:response_id])
  end

  def set_comment
    @comment = @response.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :comment_type, :parent_id)
  end

  def notify_comment_created
    # Notify response owner if different from comment author
    if @response.user != current_user
      NotificationService.create_for_user(
        @response.user,
        "comment_created",
        "New comment on your response",
        message: "#{current_user.name} commented on your response #{@response.shortcode}",
        data: {
          comment_id: @comment.id,
          response_id: @response.id,
          commenter_name: current_user.name,
          content: @comment.content.truncate(100)
        },
        mission: @response.mission
      )
    end

    # Notify other commenters (excluding the author and response owner)
    other_commenters = @response.comments.joins(:author)
      .where.not(author: [current_user, @response.user])
      .distinct
      .pluck(:author_id)

    other_commenters.each do |user_id|
      user = User.find(user_id)
      NotificationService.create_for_user(
        user,
        "comment_created",
        "New comment on response",
        message: "#{current_user.name} commented on response #{@response.shortcode}",
        data: {
          comment_id: @comment.id,
          response_id: @response.id,
          commenter_name: current_user.name,
          content: @comment.content.truncate(100)
        },
        mission: @response.mission
      )
    end
  end
end
