require 'active_job'
require 'active_support/core_ext/module/introspection'

module KittyEvents
  class HandleWorker < ActiveJob::Base
    def perform(event, object)
      if self.class.respond_to?(:module_parent)
        self.class.module_parent.handle(event, object)
      else
        self.class.parent.handle(event, object)
      end
    end
  end
end
