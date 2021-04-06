# Lucky Task

A Crystal library for creating command line tasks to be used with the [LuckyCli](https://github.com/luckyframework/lucky_cli).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lucky_task:
       github: luckyframework/lucky_task
   ```

2. Run `shards install`

## Integrating With LuckyCli

Create a file `tasks.cr` at the root of your project

```crystal
require "lucky_task"

# Using `lucky` from the command line will do nothing if you forget this
LuckyTask::Runner.run
```

## Creating Tasks

Create a `tasks` directory in the root of your project.

Update your `tasks.cr` file to require all files within that directory for them to be registered with the CLI.

```crystal
# tasks.cr
require "lucky_task"
require "./tasks/*"
```

In the directory create a file called `send_daily_notifications.cr`.

```crystal
class SendDailyNotifications < LuckyTask::Task
  summary "Send notifications to users"
  
  # Name is inferred from class name ("send_daily_notifications")
  # It can be overridden:
  #
  #   name "app.send_daily_notifications"
  
  def call
    # Code that sends notifications to all your users...
  end
end
```

## Contributing

1. Fork it (<https://github.com/luckyframework/lucky_task/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [matthewmcgarvey](https://github.com/matthewmcgarvey) - creator and maintainer
