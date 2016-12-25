require 'active_job'

class KittyEvents::HandleWorker < ActiveJob::Base
  def perform(event, object)
    KittyEvents.handle(event, object)
  end
end
