require 'active_job'

module KittyEvents
  class HandleWorker < ActiveJob::Base
    def perform(event, object)
      KittyEvents.handle(event, object)
    end
  end
end
