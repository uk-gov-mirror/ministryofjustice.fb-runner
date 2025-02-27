RSpec.describe Platform::UserDatastoreAdapter do
  subject(:adapter) do
    described_class.new(session, root_url: root_url, service_slug: service_slug)
  end

  let(:service_slug) { 'court-service' }
  let(:root_url) do
    'http://user-datastore.com'
  end
  let(:expected_url) do
    URI.join(root_url, '/service/court-service/user/8b62ea25319b4ad8a889174dca57e061')
  end
  let(:expected_headers) do
    {
      'Authorization' => 'Bearer some-token',
      'x-access-token-v2' => 'some-token',
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent' => 'Runner'
    }
  end
  let(:service_access_token) { 'some-token' }

  let(:expected_body) do
    JSON.generate({
      payload: data_encryption.encrypt(params.to_json)
    })
  end

  let(:params) do
    { question_one: 'Be careful not to choke on your aspirations.' }
  end
  let(:session) do
    {
      session_id: '8b62ea25319b4ad8a889174dca57e061',
      user_token: '474c39bf61287d4ec0aa1276f089d2e3'
    }
  end
  let(:empty_payload) do
    JSON.generate({ payload: data_encryption.encrypt('{}') })
  end
  let(:data_encryption) { DataEncryption.new(key: session[:user_token]) }

  before do
    allow_any_instance_of(Fb::Jwt::Auth::ServiceAccessToken).to receive(:generate)
      .and_return(service_access_token)
  end

  describe '#save' do
    context 'when the response is successful' do
      context 'when there is data already stored in datastore' do
        let(:existing_answers) do
          { other_question: 'Do. Or do not. There is no try.' }
        end
        let(:expected_body) do
          JSON.generate(
            {
              payload: data_encryption.encrypt(existing_answers.merge(params).to_json)
            }
          )
        end

        before do
          expect(adapter).to receive(:load_data).and_return(existing_answers)

          stub_request(:post, expected_url)
            .with(body: expected_body, headers: expected_headers)
            .to_return(status: 200, body: expected_body, headers: {})
        end

        it 'merges the whole payload and send to datastore' do
          adapter.save(params)
          expect(WebMock).to have_requested(
            :post, expected_url
          ).with(headers: expected_headers, body: expected_body)
           .once
        end
      end

      context 'when there is no data stored in datastore' do
        before do
          stub_request(:get, expected_url)
            .with(body: {}, headers: expected_headers)
            .to_return(status: 404, body: empty_payload, headers: {})

          stub_request(:post, expected_url)
            .with(body: expected_body, headers: expected_headers)
            .to_return(status: 201, body: expected_body, headers: {})
        end

        it 'sends request to datastore' do
          adapter.save(params)
          expect(WebMock).to have_requested(
            :post, expected_url
          ).with(headers: expected_headers, body: expected_body)
           .once
        end
      end
    end

    context 'when the response fails' do
      before do
        stub_request(:get, expected_url)
          .with(body: {}, headers: expected_headers)
          .to_return(status: 500, body: JSON.generate({}), headers: {})
      end

      it 'raises datastore error' do
        expect { adapter.save(params) }.to raise_error(
          Platform::ClientError
        )
      end
    end

    context 'when there is timeout' do
      context 'when there is connection timeout' do
        before do
          stub_request(:get, expected_url)
            .with(body: {}, headers: expected_headers)
            .to_timeout
        end

        it 'raises datastore timeout error' do
          expect { adapter.save(params) }.to raise_error(
            Platform::TimeoutError
          )
        end
      end

      context 'when there is request timeout' do
        before do
          stub_request(:get, expected_url)
            .with(body: {}, headers: expected_headers)
            .to_raise(Faraday::TimeoutError)
        end

        it 'raises datastore timeout error' do
          expect { adapter.save(params) }.to raise_error(
            Platform::TimeoutError
          )
        end
      end
    end
  end

  describe '#load_data' do
    context 'when returning data' do
      before do
        stub_request(:get, expected_url)
          .with(body: {}, headers: expected_headers)
          .to_return(status: 200, body: expected_body, headers: {})
      end

      it 'returns decrypted payload' do
        expect(adapter.load_data).to eq(params.stringify_keys)
      end
    end

    context 'when there is no data in payload (when user starts the form)' do
      before do
        stub_request(:get, expected_url)
          .with(body: {}, headers: expected_headers)
          .to_return(status: 200, body: empty_payload, headers: {})
      end

      it 'returns empty hash' do
        expect(adapter.load_data).to eq({})
      end
    end
  end
end
