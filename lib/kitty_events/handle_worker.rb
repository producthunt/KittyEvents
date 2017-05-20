require 'active_job'
require 'active_support/core_ext/module/introspection'

module KittyEvents
  # I'm making some changes as an example!
  # ANother change!
  class HandleWorker < ActiveJob::Base
    def perform(event, object)
      self.class.parent.handle(event, object)
    end
  end
end
