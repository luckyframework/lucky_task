require "levenshtein"

class LuckyTask::TaskNotFoundErrorMessage
  def initialize(@task_name : String, @io : IO = STDERR)
  end

  def self.print(*args) : Nil
    new(*args).print
  end

  def print : Nil
    message = "Task #{@task_name.colorize(:cyan)} not found."

    similar_task_name.try do |name|
      message += " Did you mean '#{name}'?".colorize(:yellow).to_s
    end

    @io.puts message
  end

  private def similar_task_name : String?
    Levenshtein::Finder.find(
      @task_name,
      LuckyTask::Runner.tasks.map(&.task_name),
      tolerance: 4
    )
  end
end
