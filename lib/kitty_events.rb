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
  @@handlers = {}

  mattr_reader :handlers

  class << self
    def register(*event_names)
      event_names.each do |name|
        handlers[name.to_sym] ||= []
      end
    end

    def subscribe(event, handler)
      handlers = handlers_for_event! event
      handlers << handler
    end

    def trigger(event, object)
      handlers_for_event! event

      KittyEvents::HandleWorker.perform_later(event.to_s, object)
    end

    def events
      handlers.keys
    end

    def handle(event, object)
      handlers_for_event(event) { [] }.each do |handler|
        handler.perform_later(object)
      end
    end

    private

    def handlers_for_event!(event)
      handlers_for_event(event) { raise ArgumentError, "#{event} is not registered" }
    end

    def handlers_for_event(event, &block)
      handlers.fetch(event.to_sym, &block);
    end
  end
end
