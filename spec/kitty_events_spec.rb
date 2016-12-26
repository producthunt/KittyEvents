require 'spec_helper'

describe KittyEvents do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  after(:each) do
    # Don't leak settings across tests
    described_class.class_variable_set :@@handlers, {}
  end

  let(:some_handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:another_handler) { class_double(ActiveJob::Base, perform_later: nil) }
  let(:some_object) { double('Some::Object') }

  describe '.register' do
    it 'adds event to list of events' do
      described_class.register(:vote)
      expect(described_class.registered).to include(:vote)
    end

    it 'handles event names passed as a string' do
      described_class.register('vote')
      expect(described_class.registered).to include(:vote)
    end

    it 'handles multiple events' do
      described_class.register(:vote)
      described_class.register(:post, :subscribe)

      expect(described_class.registered.sort).to eq %i(vote post subscribe).sort
    end

    it 'does not add duplicates' do
      described_class.register(:vote)
      described_class.register(:vote)

      expect(described_class.registered).to eq %i(vote)
    end
  end

  describe '.subscribe' do
    before do
      described_class.register(:vote)
    end

    it 'subscribes to an event' do
      described_class.subscribe(:vote, some_handler)

      expect(described_class.handlers[:vote]).to eq [some_handler]
    end

    it 'subscribes to an event (using string)' do
      described_class.subscribe('vote', some_handler)

      expect(described_class.handlers[:vote]).to eq [some_handler]
    end

    it 'handles multiple handlers for a single event' do
      described_class.subscribe(:vote, some_handler)
      described_class.subscribe(:vote, another_handler)

      expect(described_class.handlers[:vote]).to eq [some_handler, another_handler]
    end

    it 'raises an error when subscribing to an unregistered event' do
      expect do
        described_class.subscribe(:fake_event, some_handler)
      end.to raise_error ArgumentError
    end

    it 'raises an error when subscribing to invalid handler' do
      expect do
        described_class.subscribe(:vote, 'not a handler')
      end.to raise_error ArgumentError
    end
  end

  describe '.trigger' do
    it 'raises an error if event does not exist' do
      expect do
        described_class.trigger(:unregistered_event, some_handler)
      end.to raise_error ArgumentError
    end

    it 'handles event names pass as string' do
      allow(described_class::HandleWorker).to receive(:perform_later)
      described_class.register :event
      expect { described_class.trigger('event', some_handler) }.not_to raise_error
    end

    it 'enqueues a job to handle the event' do
      allow(described_class::HandleWorker).to receive(:perform_later)

      described_class.register(:vote)
      described_class.trigger(:vote, some_object)

      expect(described_class::HandleWorker).to have_received(:perform_later).with('vote', some_object)
    end
  end

  describe '.handle' do
    it 'fans out event to each subscribed handler' do
      described_class.register(:vote)
      described_class.subscribe(:vote, some_handler)
      described_class.subscribe(:vote, another_handler)

      described_class.handle(:vote, some_object)

      expect(some_handler).to have_received(:perform_later).with(some_object)
      expect(another_handler).to have_received(:perform_later).with(some_object)
    end
  end
end
