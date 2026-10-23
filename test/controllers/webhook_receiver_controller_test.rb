require 'test_helper'

class WebhookReceiverControllerTest < ActionController::TestCase
  tests ForemanArbiter::WebhookReceiverController

  setup do
    Setting['arbiter_webhook_secret'] = 'test-secret'
  end

  def valid_payload
    {
      event: 'state_transition',
      workload_id: '550e8400-e29b-41d4-a716-446655440001',
      ipa_principal: "mcp/#{hosts(:one).name}@EXAMPLE.COM",
      old_state: 'ATTESTING',
      new_state: 'HEALTHY',
      extra: { verdict: 'PASS' },
      per_backend: [
        { backend: 'keylime', verdict: 'PASS' },
        { backend: 'cosign', verdict: 'PASS' },
      ],
    }.to_json
  end

  def sign(body, secret = 'test-secret')
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
  end

  test 'rejects request without HMAC signature' do
    post :receive, body: valid_payload
    assert_response :unauthorized
  end

  test 'rejects request with invalid signature' do
    request.headers['X-Arbiter-Signature'] = 'sha256=invalid'
    post :receive, body: valid_payload
    assert_response :unauthorized
  end

  test 'accepts valid signed webhook' do
    body = valid_payload
    request.headers['X-Arbiter-Signature'] = sign(body)
    request.headers['Content-Type'] = 'application/json'
    post :receive, body: body
    assert_response :accepted
  end

  test 'returns 404 for unknown host' do
    payload = {
      event: 'state_transition',
      workload_id: '550e8400-e29b-41d4-a716-446655440001',
      ipa_principal: 'mcp/nonexistent.example.com@EXAMPLE.COM',
      new_state: 'HEALTHY',
      extra: { verdict: 'PASS' },
    }.to_json

    request.headers['X-Arbiter-Signature'] = sign(payload)
    request.headers['Content-Type'] = 'application/json'
    post :receive, body: payload
    assert_response :not_found
  end
end
