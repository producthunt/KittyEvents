require 'kitty_events/version'
require 'kitty_events/handle_worker'
require 'active_job'

# Super simple event system on top of ActiveJob
#
# Register a new event:
#   KittyEvents.register(:upvote)
#
# Subscribe to this event:
#   KittyEvents.subscribe(:upvote, Class::Of::EventHandler)
#
# An event handler is just a ActiveJob worker that implements .perform(event, object).
# When an event is triggered, It will fan out to all subscribers via ActiveJob
module KittyEvents
  @@events = []
  @@handlers = {}

  mattr_reader :events, :handlers

  def self.register(*event_names)
    event_names.each do |event|
      events << event
    end

    events.uniq!
  end

  def self.subscribe(event, handler)
    registered_event?(event)

    handlers[event] ||= []
    handlers[event] << handler
  end

  def self.trigger(event, object)
    registered_event?(event)

    KittyEvents::HandleWorker.perform_later(event.to_s, object)
  end

  def self.handle(event, object)
    (handlers[event.to_sym] || []).each do |handler|
      handler.perform_later(event, object)
    end
  end

  def self.registered_event?(event)
    return true if events.include? event
    raise ArgumentError, "#{event} is not registered"
  end
end
