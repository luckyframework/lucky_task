class My::CoolTask < LuckyTask::Task
  summary "This task does something awesome"

  def call
    :my_cool_task_was_called
  end
end

class Some::Other::Task < LuckyTask::Task
  summary "bar"
  name "my.custom_name"

  def help_message
    "Custom help message"
  end

  def call
  end
end

class AnotherTask < LuckyTask::Task
  summary "this should be first"

  def call
  end
end

class TaskWithArgs < LuckyTask::Task
  summary "This task has CLI args"
  arg :model_name, "This is the name of the model", shortcut: "-m", optional: true
  arg :model_type, description: "Define the model type", optional: true

  def call
    self
  end
end

class TaskWithRequiredFormatArgs < LuckyTask::Task
  summary "This task has a required arg with a format"
  arg :theme,
    description: "Specifies which theme to use. Must be dark or light",
    format: /^(dark|light)$/,
    example: "dark"

  def call
    self
  end
end

class TaskWithSwitchFlags < LuckyTask::Task
  summary "This is a task with switch flags"

  switch :force, "Use the force."
  switch :admin, description: "Set an admin?", shortcut: "-a"

  def call
    self
  end
end

class TaskWithInt32Flags < LuckyTask::Task
  summary "This is a task with int32 flags"

  int32 :zero, "going to zero in a hurry"
  int32 :uno, description: "defaults to one", shortcut: "-u", default: 1

  def call
    self
  end
end

class TaskWithFloat64Flags < LuckyTask::Task
  summary "This is a task with float64 flags"

  float64 :zero, "going to zero in a hurry"
  float64 :uno, description: "defaults to one", shortcut: "-u", default: 1
  float64 :pi, description: "defaults to PI", shortcut: "-p", default: 3.14

  def call
    self
  end
end

class TaskWithPositionalArgs < LuckyTask::Task
  summary "This is a task with positional args"

  positional_arg :model, "Define the model", format: /^[A-Z]/
  positional_arg :columns,
    "Define the columns like name:String",
    to_end: true,
    format: /\w+:[A-Z]\w+(::\w+)?/,
    example: "name:String"

  def call
    self
  end
end

class TaskWithFancyOutput < LuckyTask::Task
  summary "This is a task with some fancy output"

  def call
    output.puts "Fancy output".colorize.green
    self
  end
end
