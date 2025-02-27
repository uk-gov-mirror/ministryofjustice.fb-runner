RSpec.describe UserData do
  subject(:user_data) { described_class.new(session, adapter: adapter) }
  let(:session) { {} }
  let(:adapter) do
    class MyCustomAdapter
      def initialize(session); end

      def save(params); end

      def load_data; end
    end

    MyCustomAdapter
  end
  let(:params) { { some_question: 'some_answer' } }

  describe '#adapter' do
    context 'when adapter is overwritten in the initialise' do
      subject(:user_data) { described_class.new(session, adapter: adapter) }

      it 'returns the adapter passed in initialize' do
        expect(user_data.adapter).to be_instance_of(adapter)
      end
    end

    context 'when there is a datastore url' do
      subject(:user_data) { described_class.new(session) }

      before do
        allow(ENV).to receive(:[]).with('DATASTORE_URL')
          .and_return('http://localhost:9000')

        allow(ENV).to receive(:[]).with('SERVICE_SLUG')
          .and_return('court-or-tribunal')
      end

      it 'returns the datastore adapter' do
        expect(user_data.adapter).to be_instance_of(
          Platform::UserDatastoreAdapter
        )
      end
    end

    context 'when no adapter is passed and there is no datastore url' do
      subject(:user_data) { described_class.new(session) }

      before do
        allow(ENV).to receive(:[]).with('DATASTORE_URL').and_return('')
      end

      it 'returns the session adapter' do
        expect(user_data.adapter).to be_instance_of(SessionDataAdapter)
      end
    end
  end

  describe '#save' do
    it 'delegates to adapter' do
      expect_any_instance_of(adapter).to receive(:save).with(params)
      user_data.save(params)
    end
  end

  describe '#load_data' do
    it 'delegates to adapter' do
      expect_any_instance_of(adapter).to receive(:load_data)
      user_data.load_data
    end
  end
end
