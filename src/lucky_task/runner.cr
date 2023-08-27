class LuckyTask::Runner
  @@tasks = [] of LuckyTask::Task
  class_property? exit_with_error_if_not_found : Bool = true

  extend LuckyTask::TextHelpers

  def self.register_task(task : LuckyTask::Task) : Nil
    @@tasks.push(task)
  end

  def self.tasks : Array(LuckyTask::Task)
    @@tasks.sort_by!(&.task_name)
  end

  def self.run(args = ARGV, io : IO = STDERR)
    task_name = args.shift?

    if !task_name.nil? && {"--help", "-h"}.includes?(task_name)
      puts help_text
    elsif task_name.nil?
      io.puts <<-HELP_TEXT
      Missing a task name

      To see a list of available tasks, run #{"lucky --help".colorize(:green)}
      HELP_TEXT
    else
      if task = find_task(task_name)
        task.output = io
        task.print_help_or_call(args)
      else
        TaskNotFoundErrorMessage.print(task_name)
        if exit_with_error_if_not_found?
          exit(127)
        end
      end
    end
  end

  def self.help_text : Nil
    puts <<-HELP_TEXT
    Usage: lucky name.of.task [options]

    Available tasks:

    #{tasks_list}
    HELP_TEXT
  end

  def self.find_task(task_name : String) : LuckyTask::Task?
    @@tasks.find { |task| task.task_name == task_name }
  end

  def self.tasks_list : String
    String.build do |list|
      tasks.each do |task|
        list << ("  #{arrow} " + task.task_name).colorize(:green)
        list << list_padding_for(task.task_name)
        list << task.summary
        list << "\n"
      end
    end
  end

  def self.list_padding_for(task_name) : String
    " " * (longest_task_name - task_name.size + 2)
  end

  def self.longest_task_name : Int32
    tasks.max_of(&.task_name.size)
  end
end
