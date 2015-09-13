class TasksController < ApplicationController

  def index
    @new_task = Tasks.new
  end

  def create
    @task = Task.new(task_params)
    @save_success = @task.save
  end

  private
  def task_params
    params.require(:task).permit(:title)
  end
end
