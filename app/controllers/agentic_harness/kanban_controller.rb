# frozen_string_literal: true

module AgenticHarness
class KanbanController < ApplicationController
  def index
    @category = params[:category]
    @categories = TaskPage::CATEGORIES
    @columns = TaskPage.all_by_column(category: @category)
    @backlog = TaskPage.backlog
  end

  def show
    @task = TaskPage.find(params[:column], params[:slug])

    unless @task
      redirect_to kanban_path, alert: "Task not found: #{params[:column]}/#{params[:slug]}"
    end
  end

  def backlog
    @backlog = TaskPage.backlog

    unless @backlog
      redirect_to kanban_path, alert: "No BACKLOG.md found in tasks/"
    end
  end

  def edit
    @task = TaskPage.find(params[:column], params[:slug])
    redirect_to kanban_path, alert: "Task not found" unless @task
  end

  def update
    @task = TaskPage.find(params[:column], params[:slug])
    unless @task
      redirect_to kanban_path, alert: "Task not found"
      return
    end

    content = params[:content].to_s
    @task.path.write(content)
    redirect_to kanban_task_path(column: @task.column, slug: @task.slug),
                notice: "Task saved."
  end

  def destroy
    @task = TaskPage.find(params[:column], params[:slug])
    unless @task
      redirect_to kanban_path, alert: "Task not found"
      return
    end

    @task.path.delete
    redirect_to kanban_path, notice: "#{@task.slug} deleted."
  end

  def archive
    @task = TaskPage.find(params[:column], params[:slug])
    unless @task
      redirect_to kanban_path, alert: "Task not found"
      return
    end

    TaskPage.move(@task, "90_archive")
    redirect_to kanban_path, notice: "#{@task.slug} archived."
  end

  def move
    task = TaskPage.find(params[:column], params[:slug])
    return render json: { error: "Task not found" }, status: :not_found unless task

    target_column = params[:target_column].to_s
    unless TaskPage::COLUMNS.key?(target_column)
      return render json: { error: "Invalid column" }, status: :unprocessable_entity
    end

    moved = TaskPage.move(task, target_column)
    unless moved
      return render json: { error: "Move failed" }, status: :internal_server_error
    end

    render json: { ok: true, slug: moved.slug, column: moved.column }
  end

  def reorder_column
    column = params[:column].to_s
    unless TaskPage::COLUMNS.key?(column)
      return render json: { error: "Invalid column" }, status: :unprocessable_entity
    end

    TaskPage.reorder_column(column, Array(params[:slugs]))
    render json: { ok: true }
  end

end
end
