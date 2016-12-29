require 'kitty_events/version'
require 'kitty_events/handle_worker'
require 'active_job'

# Super simple event system on top of ActiveJob
#
# # Create event object
# module ApplicationEvents
#   extends KittyEvents
#
#   # Register a new event:
#   register :upvote
#
#   # Subscribe to this event:
#   subscribe :upvote, SpamDetector::UpvoteEventHandler
# end
#
# # Trigger event
# ApplicationEvents.trigger :upvote, vote
#
# An event handler is just a ActiveJob worker that implements .perform(object).
# When an event is triggered, It will fan out to all subscribers via ActiveJob
module KittyEvents
  def self.extended(mod)
    mod.class_variable_set :@@handlers, {}
    mod.mattr_reader :handlers
    mod.const_set 'HandleWorker', Class.new(::KittyEvents::HandleWorker)
  end

  def handle_worker
    self::HandleWorker
  end

  def register(*event_names)
    event_names.each do |name|
      handlers[name.to_sym] ||= []
    end
  end

  def registered
    handlers.keys
  end

  def subscribe(event, handler)
    ensure_valid_handler handler

    handlers = handlers_for_event! event
    handlers << handler
  end

  def trigger(event, object)
    handlers_for_event! event

    handle_worker.perform_later(event.to_s, object)
  end

  def handle(event, object)
    handlers_for_event(event) { [] }.each do |handler|
      handler.perform_later(object)
    end
  end

  private

  def ensure_valid_handler(handler)
    raise ArgumentError, "#{handler} has to respond to perform_later" unless handler.respond_to? :perform_later
  end

  def handlers_for_event!(event)
    handlers_for_event(event) { raise ArgumentError, "#{event} is not registered" }
  end

  def handlers_for_event(event, &block)
    handlers.fetch(event.to_sym, &block)
  end
end
