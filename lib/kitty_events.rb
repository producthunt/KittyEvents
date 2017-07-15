require 'kitty_events/version'
require 'kitty_events/handle_worker'

# Super simple event system on top of ActiveJob
#
# # Create event emitter
# module ApplicationEvents
#   extends KittyEvents
#
#   # Subscribe to event
#   # An event handler is ActiveJob worker that implements `.perform(object)`
#   event :upvote, [
#    SpamDetector::UpvoteEventHandler,
#    Achievements::UpvoteEventHandler,
#    CacheCleaner::UpvoteEventHandler
#  ]
# end
#
# # Trigger event
# # When an event is triggered, It will fan out to all handlers via ActiveJob
# ApplicationEvents.trigger :upvote, vote
module KittyEvents
  def self.extended(mod)
    mod.class_variable_set :@@handlers, {}
    mod.mattr_reader :handlers
    mod.const_set 'HandleWorker', Class.new(::KittyEvents::HandleWorker)
  end

  def new_method
    false
  end

  def handle_worker
    self::HandleWorker
  end

  def event(event, event_handlers)
    raise ArgumentError, "#{event} already registered" if handlers[event.to_sym]

    handlers[event.to_sym] = validate_handlers(event_handlers)
  end

  def trigger(event, object)
    raise ArgumentError, "#{event} is not registered" unless handlers[event.to_sym]

    handle_worker.perform_later(event.to_s, object)
  end

  def handle(event, object)
    (handlers[event.to_sym] || []).each do |handler|
      handler.perform_later(object)
    end
  end

  private

  def validate_handlers(handlers)
    Array(handlers).each do |handler|
      unless handler.respond_to? :perform_later
        raise ArgumentError, "#{handler} has to respond to `perform_later`"
      end
    end
  end
end
