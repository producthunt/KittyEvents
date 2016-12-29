require 'active_job'

module KittyEvents
  class HandleWorker < ActiveJob::Base
    def perform(event, object)
      self.class.parent.handle(event, object)
    end
  end
end
