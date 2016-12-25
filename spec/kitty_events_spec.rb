require 'spec_helper'

describe KittyEvents do
  it 'has a version number' do
    expect(KittyEvents::VERSION).not_to be nil
  end

  after(:each) do
    # Don't leak settings across tests
    described_class.class_variable_set :@@events, []
    described_class.class_variable_set :@@handlers, {}
  end

  let(:some_handler) { class_double(ActiveJob::Base) }
  let(:another_handler) { class_double(ActibeJob::Base) }
  let(:some_object) { double('Some::Object') }

  describe '.register' do
    it 'adds event to list of events' do
      described_class.register(:vote)
      expect(described_class.events).to include(:vote)
    end

    it 'handles multiple events' do
      described_class.register(:vote, :post, :subscribe)

      expect(described_class.events).to include(:vote)
      expect(described_class.events).to include(:post)
      expect(described_class.events).to include(:subscribe)
    end

    it 'does not add duplicates' do
      described_class.register(:vote)
      described_class.register(:vote)

      expect(described_class.events.length).to eq 1
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
  end

  describe '.trigger' do
    it 'raises an error if event does not exist' do
      expect do
        described_class.trigger(:unregistered_event, some_handler)
      end.to raise_error ArgumentError
    end

    it 'enqueues a job to handle the event' do
      allow(KittyEvents::HandleWorker).to receive(:perform_later)

      described_class.register(:vote)
      described_class.trigger(:vote, some_object)

      expect(KittyEvents::HandleWorker).to have_received(:perform_later).with('vote', some_object)
    end
  end

  describe '.handle' do
    it 'fans out event to each subscribed handler' do
      allow(some_handler).to receive(:perform_later)
      allow(another_handler).to receive(:perform_later)

      described_class.register(:vote)
      described_class.subscribe(:vote, some_handler)
      described_class.subscribe(:vote, another_handler)

      described_class.handle(:vote, some_object)

      expect(some_handler).to have_received(:perform_later).with(:vote, some_object)
      expect(another_handler).to have_received(:perform_later).with(:vote, some_object)
    end
  end
end
