abstract class LuckyTask::Task
  macro inherited
    PARSER_OPTS = [] of Symbol
    @positional_arg_count : Int32 = 0
    property option_parser : OptionParser = OptionParser.new
    property output : IO = STDOUT

    {% if !@type.abstract? %}
      LuckyTask::Runner.register_task(self)
    {% end %}

    # The name of your task as derived by the class name
    # Use the `task_name` macro to define a custom task name
    def self.task_name : String
      "{{@type.name.gsub(/::/, ".").underscore}}"
    end

    # By default, task summaries are optional.
    # Use the `summary` macro to define a custom summary
    def self.task_summary : String
      ""
    end

    # The help text to be displayed when a help flag
    # is passed in (e.g. -h, --help)
    # Use the `help_message`
    def self.task_help_message : String
      <<-TEXT.strip
      #{task_summary}

      Run this task with 'lucky #{task_name}'
      TEXT
    end

    def print_help_or_call(args : Array(String))
      if wants_help_message?(args)
        output.puts self.class.task_help_message
      else
        \{% for opt in @type.constant(:PARSER_OPTS) %}
        set_opt_for_\{{ opt.id }}(args)
        \{% end %}
        option_parser.parse(args)
        call
      end
    end

    private def wants_help_message?(args) : Bool
      args.any? { |arg| {"--help", "-h", "help"}.includes?(arg) }
    end
  end

  # The general description of what this task does
  #
  # This is used in the help_text when a help flag is passed
  # to the task through the CLI
  macro summary(summary_text)
    def self.task_summary : String
      {{summary_text}}
    end
  end

  # Renames the task name for CLI use
  #
  # By default the task name is derived from the full module and class name.
  # However if that task name is not desired, a custom one can be set.
  #
  # ```
  # class Dev::Prime < LuckyTask::Task
  #   # Would be "dev.prime" by default, but we want to set it to "dev.setup":
  #   task_name "dev.setup"
  #   summary "Seed the development database with example data"
  #
  #   # other methods, etc.
  # end
  # ```
  macro name(name_text)
    def self.task_name : String
      {{name_text}}
    end
  end

  # Customize your help message with the provided `help_text`
  #
  # ```
  # class KeyGen < LuckyTask::Task
  #   summary "Generate a new key"
  #   help_message "Call lucky key_gen to generate a new key"
  #
  #   # other methods, etc.
  # end
  # ```
  macro help_message(help_text)
    def self.task_help_message : String
      {{help_text}}
    end
  end

  # Creates a method of `arg_name` that returns the value passed in from the CLI.
  # The CLI arg position is based on the order in which `positional_arg` is specified
  # with the first call being position 0, and so on.
  #
  # If your arg takes more than one value, you can set `to_end` to true to capture all
  # args from this position to the end. This will make your `arg_name` method return `Array(String)`.
  #
  # * `arg_name` : String - The name of the argument
  # * `description` : String - The help text description for this option
  # * `to_end` : Bool - Capture all args from this position to the end.
  # * `format` : Regex - The format you expect the args to match
  # * `example` : String - An example string that matches the given `format`
  macro positional_arg(arg_name, description, to_end = false, format = nil, example = nil)
    {% PARSER_OPTS << arg_name %}
    @{{ arg_name.id }} : {% if to_end %}Array(String){% else %}String{% end %} | Nil

    def set_opt_for_{{ arg_name.id }}(args : Array(String))
      {% if to_end %}
        value = args[@positional_arg_count..-1]
      {% else %}
        value = args[@positional_arg_count]?
      {% end %}
      {% if format %}
      matches = value.is_a?(Array) ? value.all?(&.=~({{ format }})) : value =~ {{ format }}
      if !matches
        raise <<-ERROR
        Invalid format for {{ arg_name.id }}. It should match {{ format }}
        {% if example %}
          Example: {{ example.id }}
        {% end %}
        ERROR
      end
      {% end %}
      @{{ arg_name.id }} = value
      @positional_arg_count += 1
    end

    def {{ arg_name.id }} : {% if to_end %}Array(String){% else %}String{% end %}
      if @{{ arg_name.id }}.nil?
        raise "{{ arg_name.id }} is required, but no value was passed."
      end
      @{{ arg_name.id }}.as({% if to_end %}Array(String){% else %}String{% end %})
    end
  end

  # Creates a method of `arg_name` that returns the value passed in from the CLI.
  # The CLI arg is specified by the `--arg_name=VALUE` flag.
  #
  # * `arg_name` : String - The name of the argument
  # * `description` : String - The help text description for this option
  # * `shorcut` : String - An optional short flag (e.g. -a VALUE)
  # * `optional` : Bool - When false, raise exception if this arg is not passed
  # * `format` : Regex - The format you expect the args to match
  # * `example` : String - An example string that matches the given `format`
  macro arg(arg_name, description, shortcut = nil, optional = false, format = nil, example = nil)
    {% PARSER_OPTS << arg_name %}
    @{{ arg_name.id }} : String?

    def set_opt_for_{{ arg_name.id }}(unused_args : Array(String))
      option_parser.on(
        {% if shortcut %}"{{ shortcut.id }} {{ arg_name.stringify.upcase.id }}",{% end %}
        "--{{ arg_name.id.stringify.underscore.gsub(/_/, "-").id }}={{ arg_name.id.stringify.upcase.id }}",
        {{ description }}
      ) do |value|
        value = value.strip
        {% if format %}
        if value !~ {{ format }}
          raise <<-ERROR
          Invalid format for {{ arg_name.id }}. It should match {{ format }}
          {% if example %}
            Example: {{ example.id }}
          {% end %}
          ERROR
        end
        {% end %}
        @{{ arg_name.id }} = value
      end
    end

    def {{ arg_name.id }} : String{% if optional %}?{% end %}
      {% if !optional %}
        if @{{ arg_name.id }}.nil?
          raise <<-ERROR
          {{ arg_name.id }} is required, but no value was passed.

          Try this...

            {% if shortcut %}{{ shortcut.id }} SOME_VALUE{% end %}
            --{{ arg_name.id.stringify.underscore.gsub(/_/, "-").id }}=SOME_VALUE
          ERROR
        end
        @{{ arg_name.id }}.as(String)
      {% else %}
        @{{ arg_name.id }}
      {% end %}
    end
  end

  # Creates a method of `arg_name` where the return value is boolean.
  # If the flag `--arg_name` is passed, the value is `true`.
  #
  # * `arg_name` : String - The name of the argument
  # * `description` : String - The help text description for this option
  # * `shorcut` : String - An optional short flag (e.g. `-a`)
  macro switch(arg_name, description, shortcut = nil)
    {% PARSER_OPTS << arg_name %}
    @{{ arg_name.id }} : Bool = false

    def set_opt_for_{{ arg_name.id }}(unused_args : Array(String))
      option_parser.on(
        {% if shortcut %}"{{ shortcut.id }}",{% end %}
        "--{{ arg_name.id.stringify.underscore.gsub(/_/, "-").id }}",
        {{ description }}
      ) do
        @{{ arg_name.id }} = true
      end
    end

    def {{ arg_name.id }}? : Bool
      @{{ arg_name.id }}
    end
  end

  # Creates a method of `arg_name` where the return value is an Int32.
  # If the flag `--arg_name` is passed, the result is the value passed, otherwise is set to
  # the specified default, or `0` when not specified.
  #
  # * `arg_name` : String - The name of the argument
  # * `description` : String - The help text description for this option
  # * `shorcut` : String - An optional short flag (e.g. `-a`)
  # * `default` : Int32 - An optional default value (`0` is default when omittted)
  #
  # Example:
  #      int32 :limit, "limit (1000, 10_000, etc.)", shortcut: "-l", default: 1_000
  macro int32(arg_name, description, shortcut = nil, default = nil)
    {% PARSER_OPTS << arg_name %}
    @{{ arg_name.id }} : Int32 = {{ default || 0 }}

    def set_opt_for_{{ arg_name.id }}(unused_args : Array(String))
      option_parser.on(
        {% if shortcut %}"{{ shortcut.id }} {{ arg_name.stringify.upcase.id }}",{% end %}
        "--{{ arg_name.id.stringify.underscore.gsub(/_/, "-").id }}={{ arg_name.id.stringify.upcase.id }}",
        {{ description }}
      ) do |value|
        value = value.strip
        if value !~ /^[\+\-]?[0-9\_]+$/
          raise <<-ERROR
            #{value.inspect} is an invalid value for {{ arg_name.id }}. It should be a valid Int32
            Examples: 1 or 1000 or 10_000 or -1
          ERROR
        end
        @{{ arg_name.id }} = value.gsub(/[\_]/, "").to_i32
      end
    end

    def {{ arg_name.id }} : Int32
      @{{ arg_name.id }}
    end
  end

  # Creates a method of `arg_name` where the return value is an Float64.
  # If the flag `--arg_name` is passed, the result is the value passed, otherwise is set to
  # the specified default, or `0.0` when not specified.
  #
  # * `arg_name` : String - The name of the argument
  # * `description` : String - The help text description for this option
  # * `shorcut` : String - An optional short flag (e.g. `-a`)
  # * `default` : Float64 - An optional default value (`0.0` is default when omittted)
  #
  # Example:
  #      float64 :threshold, "(0.1, 3.14, -5.1, etc.)", shortcut: "-t", default: 2.0
  macro float64(arg_name, description, shortcut = nil, default = nil)
    {% PARSER_OPTS << arg_name %}
    @{{ arg_name.id }} : Float64 = {{ default || 0.0 }}

    def set_opt_for_{{ arg_name.id }}(unused_args : Array(String))
      option_parser.on(
        {% if shortcut %}"{{ shortcut.id }} {{ arg_name.stringify.upcase.id }}",{% end %}
        "--{{ arg_name.id.stringify.underscore.gsub(/_/, "-").id }}={{ arg_name.id.stringify.upcase.id }}",
        {{ description }}
      ) do |value|
        value = value.strip.gsub("_", "")
        if value !~ /^[+-]?([0-9]*[.])?[0-9]+$/
          raise <<-ERROR
            #{value.inspect} is an invalid value for {{ arg_name.id }}. It should be a valid Float64
            Examples: 1 or 1.0 or 1_000.0 or -1.0
          ERROR
        end
        @{{ arg_name.id }} = value.to_f64
      end
    end

    def {{ arg_name.id }} : Float64
      @{{ arg_name.id }}
    end
  end

  abstract def call
end
