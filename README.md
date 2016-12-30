# :heart_eyes_cat: KittyEvents

Super simple event system built on top of ActiveJob.

KittyEvents implements the [publish/subscribe](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) pattern using ActiveJob. You setup your events and list the subscribers for them. When an event is triggered, KittyEvents will fanout the event to each of your subscribers.

### Why use this
- Uses ActiveJob. No need to add a new dependency for pub/sub.
- Reduce complexity/establish patterns. Can be used to replace `after_commit`'s. This creates easier to follow/read code. Less surprises = good!
- Replace several `perform_later`'s with a single event `trigger`. Reducing the amount of I/O happening in request (less I/O = faster response times)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kitty_events'
```

And then execute:

    $ bundle install

## Usage

In Rails, setup your events and subscribers in an initializer.

```Ruby
# config/initializers/application_events.rb
module ApplicationEvents
  extend KittyEvents

  event :user_signup, [
    WelcomeEmailWorker,
    WelcomeTweetWorker,
    SyncProfileImageWorker,
    ExampleWorker.set(wait: 5.minutes), # standard ActiveJob settings work as well!
  ]
  
  event :user_upvote, [
    SomeWorker,
    AnotherWorker,
  ]
end
```

Each subscriber must be an ActiveJob and respond to `perform_later(object)`.

```Ruby
class ExampleWorker < ActiveJob::Base
  def perform(user)
    # do work
  end
end
```

Then in your application, to trigger an event. Do the following.

```Ruby
ApplicationEvents.trigger(:user_signup, user)
```

Using the above example, triggering this event would pass `user` to each of the subscribers defined in our initializer:
```
WelcomeEmailWorker,
WelcomeTweetWorker,
SyncProfileImageWorker,
ExampleWorker.set(wait: 5.minutes)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/producthunt/kittyevents. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

[![Product Hunt](http://i.imgur.com/dtAr7wC.png)](https://www.producthunt.com)

```
 _________________
< The MIT License >
 -----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
