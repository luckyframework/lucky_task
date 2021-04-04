require "../spec_helper"

include HaveDefaultHelperMessageMatcher

describe LuckyTask::Runner do
  it "adds tasks to the runner when task classes are created" do
    expected_task_names = ["another_task", "my.cool_task", "my.custom_name"]

    task_names = LuckyTask::Runner.tasks.map(&.name)

    expected_task_names.each do |expected_task_name|
      task_names.should contain(expected_task_name)
    end
  end

  it "lists all the available tasks" do
    LuckyTask::Runner.tasks.map(&.name).each do |name|
      LuckyTask::Runner.tasks_list.should contain(name)
    end
  end

  it "calls the task if one is found" do
    LuckyTask::Runner
      .run(args: ["my.cool_task"])
      .should have_called_my_cool_task
  end

  it "prints the help_message for a found task when a help flag is passed" do
    %w(--help -h help).each do |help_arg|
      io = IO::Memory.new
      LuckyTask::Runner.run(args: ["my.cool_task", help_arg], io: io)
      io.to_s.chomp.should have_default_help_message
    end
  end

  it "does not call the task if no args passed" do
    LuckyTask::Runner
      .run(args: [] of String)
      .should_not have_called_my_cool_task
  end

  it "does not call the task task is not found" do
    begin
      LuckyTask::Runner.exit_with_error_if_not_found = false

      LuckyTask::Runner
        .run(args: ["not.real"])
        .should_not have_called_my_cool_task
    ensure
      LuckyTask::Runner.exit_with_error_if_not_found = true
    end
  end
end

private def have_called_my_cool_task
  eq :my_cool_task_was_called
end
