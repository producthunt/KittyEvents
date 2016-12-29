require 'spec_helper'

describe KittyEvents do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  def events
    @events ||= Module.new do
      extend KittyEvents
    end
  end

  let(:handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:another_handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:object) { 'object' }

  describe '.event' do
    it 'subscribes to an event (using symbol for event name)' do
      events.event(:vote, handler)

      expect(events.handlers[:vote]).to eq [handler]
    end

    it 'subscribes to an event (using string for event name)' do
      events.event('vote', handler)

      expect(events.handlers[:vote]).to eq [handler]
    end

    it 'handles multiple handlers for a single event' do
      events.event(:vote, [handler, another_handler])

      expect(events.handlers[:vote]).to eq [handler, another_handler]
    end

    it 'raises an error when subscribing to invalid handler' do
      expect { events.event(:vote, 'not a handler') }.to raise_error ArgumentError
    end

    it 'raises an error when subscribe to event twice' do
      events.event(:vote, handler)

      expect { events.event(:vote, handler) }.to raise_error ArgumentError
    end
  end

  describe '.trigger' do
    before do
      allow(events.handle_worker).to receive(:perform_later)
    end

    it 'raises an error when event does not exist' do
      expect { events.trigger(:unregistered_event, handler) }.to raise_error ArgumentError
    end

    it 'enqueues a job to handle the event (using string for event name)' do
      events.event :vote, handler

      events.trigger('vote', some: object)

      expect(events.handle_worker).to have_received(:perform_later).with('vote', some: object)
    end

    it 'enqueues a job to handle the event (using symbol for event name)' do
      events.event :vote, handler

      events.trigger(:vote, some: object)

      expect(events.handle_worker).to have_received(:perform_later).with('vote', some: object)
    end
  end

  describe '.handle' do
    it 'fans out event to each subscribed handler' do
      events.event(:vote, [handler, another_handler])
      events.handle(:vote, object)

      expect(handler).to have_received(:perform_later).with(object)
      expect(another_handler).to have_received(:perform_later).with(object)
    end

    it 'does not raises when event does not exist' do
      expect { events.handle(:unregistered_event, object) }.not_to raise_error
    end
  end

  describe 'integration', active_job: :inline do
    Recorder = Module.new

    TestRegisterHandler = Class.new(ActiveJob::Base) do
      self.queue_adapter = :inline

      def perform(object)
        Recorder.record(:register_handler, object)
      end
    end

    TestVoteHandler1 = Class.new(ActiveJob::Base) do
      self.queue_adapter = :inline

      def perform(object)
        Recorder.record(:vote_handler_1, object)
      end
    end

    TestVoteHandler2 = Class.new(ActiveJob::Base) do
      self.queue_adapter = :inline

      def perform(object)
        Recorder.record(:vote_handler_2, object)
      end
    end

    class TestEvents
      extend KittyEvents

      handle_worker.queue_adapter = :inline
      handle_worker.logger = nil

      event :register, [
        TestRegisterHandler
      ]

      event :vote, [
        TestVoteHandler1,
        TestVoteHandler2
      ]
    end

    before do
      allow(Recorder).to receive(:record)
    end

    it 'delivers vote events' do
      TestEvents.trigger :vote, object

      expect(Recorder).to have_received(:record).with :vote_handler_1, object
      expect(Recorder).to have_received(:record).with :vote_handler_2, object
      expect(Recorder).not_to have_received(:record).with :register_handler, object
    end

    it 'delivers register events' do
      TestEvents.trigger :register, object

      expect(Recorder).not_to have_received(:record).with :vote_handler_1, object
      expect(Recorder).not_to have_received(:record).with :vote_handler_2, object
      expect(Recorder).to have_received(:record).with :register_handler, object
    end
  end
end
