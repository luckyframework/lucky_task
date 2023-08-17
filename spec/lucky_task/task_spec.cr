require "../spec_helper"

include HaveDefaultHelperMessageMatcher

private abstract class ShouldNotBlowUpForAbstractClasses < LuckyTask::Task
end

describe LuckyTask::Task do
  it "creates a task_name from the class name when inheriting" do
    My::CoolTask.new.task_name.should eq "my.cool_task"
  end

  it "uses a specified task_name over the auto generated task_name" do
    Some::Other::Task.new.task_name.should eq "my.custom_name"
  end

  it "creates summary text" do
    My::CoolTask.new.summary.should eq "This task does something awesome"
  end

  it "has a default help message" do
    message = My::CoolTask.new.help_message
    message.should contain "Run this task with 'lucky my.cool_task'"
    message.should contain(My::CoolTask.new.summary)
  end

  describe "print_help_or_call" do
    it "prints the help_message for a found task when a help flag is passed" do
      %w(--help -h help).each do |help_arg|
        task = My::CoolTask.new
        task.output = IO::Memory.new
        task.print_help_or_call(args: [help_arg])
        task.output.to_s.should have_default_help_message
      end
    end

    it "prints a custom help_message when set" do
      task = Some::Other::Task.new
      task.output = IO::Memory.new
      task.print_help_or_call(args: ["-h"])
      task.output.to_s.chomp.should eq "Custom help message"
    end
  end

  describe "with command line args" do
    it "creates methods for the args and returns their values" do
      task = TaskWithArgs.new.print_help_or_call(args: ["--model-name=User", "--model-type=Polymorphic"]).as(TaskWithArgs)
      task.model_name.should eq "User"
      task.model_type.should eq "Polymorphic"
    end

    it "allows the args to be optional" do
      task = TaskWithArgs.new.print_help_or_call(args: ["--model-name=User"]).as(TaskWithArgs)
      task.model_name.should eq "User"
      task.model_type.should eq nil
    end

    it "allows using an arg shortcut" do
      task = TaskWithArgs.new.print_help_or_call(args: ["-m User"]).as(TaskWithArgs)
      task.model_name.should eq "User"
    end

    it "raises an error when an arg is required and not passed" do
      task = TaskWithRequiredFormatArgs.new.print_help_or_call(args: [""]).as(TaskWithRequiredFormatArgs)
      expect_raises(Exception, /--theme=SOME_VALUE/) do
        task.theme
      end
    end

    it "raises an error if the value doesn't match the format" do
      expect_raises(Exception, /Invalid format for theme/) do
        TaskWithRequiredFormatArgs.new.print_help_or_call(args: ["--theme=Spooky"])
      end
    end

    it "provides an example for the error message on args" do
      expect_raises(Exception, /Example: dark/) do
        TaskWithRequiredFormatArgs.new.print_help_or_call(args: ["--theme=Spooky"])
      end
    end

    it "sets switch flags that default to false" do
      task = TaskWithSwitchFlags.new.print_help_or_call(args: [] of String).as(TaskWithSwitchFlags)
      task.admin?.should eq false
    end

    it "sets switch flags from args" do
      task = TaskWithSwitchFlags.new.print_help_or_call(args: ["-a"]).as(TaskWithSwitchFlags)
      task.admin?.should eq true
    end

    it "sets int32 flags that default to 0" do
      task = TaskWithInt32Flags.new.print_help_or_call(args: [] of String).as(TaskWithInt32Flags)
      task.zero.should eq 0
      task.uno.should eq 1
    end

    it "sets int32 flags from args" do
      task = TaskWithInt32Flags.new.print_help_or_call(args: ["-u 10000", "--zero=1_000"]).as(TaskWithInt32Flags)
      task.zero.should eq 1_000
      task.uno.should eq 10_000
      expect_raises(Exception, /"nada" is an invalid value for uno/) do
        TaskWithInt32Flags.new.print_help_or_call(args: ["-u nada"])
      end
    end

    it "sets explicit negative/positive int32 flags from args" do
      task = TaskWithInt32Flags.new.print_help_or_call(args: ["-u -10_000", "--zero=+1_000"]).as(TaskWithInt32Flags)
      task.zero.should eq 1_000
      task.uno.should eq -10_000
    end

    it "sets float64 flags that default to 0" do
      task = TaskWithFloat64Flags.new.print_help_or_call(args: [] of String).as(TaskWithFloat64Flags)
      task.zero.should eq 0.0
      task.uno.should eq 1.0
      task.pi.should eq 3.14
    end

    it "sets float64 flags from args" do
      task = TaskWithFloat64Flags.new.print_help_or_call(args: ["-u 123_456.789", "--zero=1_000"]).as(TaskWithFloat64Flags)
      task.zero.should eq 1_000.0
      task.uno.should eq 123_456.789
      task.pi.should eq 3.14
      expect_raises(Exception, /"nada" is an invalid value for uno/) do
        TaskWithFloat64Flags.new.print_help_or_call(args: ["-u nada"])
      end
    end

    it "sets explicit negative/positive float64 flags from args" do
      task = TaskWithFloat64Flags.new.print_help_or_call(args: ["-u -100", "--zero=+505.1"]).as(TaskWithFloat64Flags)
      task.zero.should eq 505.1
      task.uno.should eq -100.0
    end

    it "allows positional args that do not require a flag name" do
      task = TaskWithPositionalArgs.new.print_help_or_call(args: ["User", "name:String", "email:String"]).as(TaskWithPositionalArgs)
      task.model.should eq "User"
      task.columns.should eq ["name:String", "email:String"]
    end

    it "raises an error if the positional arg doesn't match the format" do
      expect_raises(Exception, /Invalid format for model/) do
        TaskWithPositionalArgs.new.print_help_or_call(args: ["user", "name"])
      end
    end

    it "provides an example for the error message on positional_arg" do
      expect_raises(Exception, /Example: name:String/) do
        TaskWithPositionalArgs.new.print_help_or_call(args: ["User", "name"])
      end
    end
  end

  describe "output" do
    it "allows you to specify where the output is written to" do
      task = TaskWithFancyOutput.new
      task.output = IO::Memory.new

      task.call
      task.output.to_s.should contain "Fancy output"
    end
  end
end
