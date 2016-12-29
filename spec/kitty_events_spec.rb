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

  let(:some_handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:another_handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:some_object) { double('Some::Object') }

  describe '.register' do
    it 'adds event to list of events' do
      events.register(:vote)
      expect(events.registered).to include(:vote)
    end

    it 'handles event names passed as a string' do
      events.register('vote')
      expect(events.registered).to include(:vote)
    end

    it 'handles multiple events' do
      events.register(:vote)
      events.register(:post, :subscribe)

      expect(events.registered.sort).to eq %i(vote post subscribe).sort
    end

    it 'does not add duplicates' do
      events.register(:vote)
      events.register(:vote)

      expect(events.registered).to eq %i(vote)
    end
  end

  describe '.subscribe' do
    before do
      events.register(:vote)
    end

    it 'subscribes to an event' do
      events.subscribe(:vote, some_handler)

      expect(events.handlers[:vote]).to eq [some_handler]
    end

    it 'subscribes to an event (using string)' do
      events.subscribe('vote', some_handler)

      expect(events.handlers[:vote]).to eq [some_handler]
    end

    it 'handles multiple handlers for a single event' do
      events.subscribe(:vote, some_handler)
      events.subscribe(:vote, another_handler)

      expect(events.handlers[:vote]).to eq [some_handler, another_handler]
    end

    it 'raises an error when subscribing to an unregistered event' do
      expect do
        events.subscribe(:fake_event, some_handler)
      end.to raise_error ArgumentError
    end

    it 'raises an error when subscribing to invalid handler' do
      expect do
        events.subscribe(:vote, 'not a handler')
      end.to raise_error ArgumentError
    end
  end

  describe '.trigger' do
    before do
      allow(events::HandleWorker).to receive(:perform_later)

      events.register :vote
    end

    it 'raises an error if event does not exist' do
      expect do
        events.trigger(:unregistered_event, some_handler)
      end.to raise_error ArgumentError
    end

    it 'handles event names pass as string' do
      expect { events.trigger('vote', some_handler) }.not_to raise_error
    end

    it 'enqueues a job to handle the event' do
      events.trigger(:vote, some: some_object)

      expect(events::HandleWorker).to have_received(:perform_later).with('vote', some: some_object)
    end
  end

  describe '.handle' do
    it 'fans out event to each subscribed handler' do
      events.register(:vote)
      events.subscribe(:vote, some_handler)
      events.subscribe(:vote, another_handler)

      events.handle(:vote, some_object)

      expect(some_handler).to have_received(:perform_later).with(some_object)
      expect(another_handler).to have_received(:perform_later).with(some_object)
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

      register :register, :vote

      subscribe :register, TestRegisterHandler

      subscribe :vote, TestVoteHandler1
      subscribe :vote, TestVoteHandler2
    end

    before do
      allow(Recorder).to receive(:record)
    end

    it 'delivers vote events' do
      TestEvents.trigger :vote, 'post_vote'

      expect(Recorder).to have_received(:record).with :vote_handler_1, 'post_vote'
      expect(Recorder).to have_received(:record).with :vote_handler_2, 'post_vote'
      expect(Recorder).not_to have_received(:record).with :register_handler, 'post_vote'
    end

    it 'delivers register events' do
      TestEvents.trigger :register, 'user'

      expect(Recorder).not_to have_received(:record).with :vote_handler_1, 'user'
      expect(Recorder).not_to have_received(:record).with :vote_handler_2, 'user'
      expect(Recorder).to have_received(:record).with :register_handler, 'user'
    end
  end
end
