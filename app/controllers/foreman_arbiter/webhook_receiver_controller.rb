module ForemanArbiter
  class WebhookReceiverController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_login
    before_action :verify_hmac_signature

    def receive
      payload = JSON.parse(request.body.read)

      host = resolve_host(payload)
      unless host
        render json: { error: 'host not found' }, status: :not_found
        return
      end

      record = AttestationRecord.create!(
        host: host,
        arbiter_workload_id: payload['workload_id'],
        arbiter_state: payload.dig('new_state') || payload.dig('state'),
        composite_verdict: payload.dig('extra', 'verdict') || 'UNAVAILABLE',
        per_backend: payload.dig('per_backend') || [],
        webhook_payload: payload,
        received_at: Time.current,
      )

      refresh_host_status(host, record)

      render json: { status: 'accepted', record_id: record.id }, status: :accepted
    end

    private

    def verify_hmac_signature
      secret = Setting['arbiter_webhook_secret']
      return head(:ok) if secret.blank?

      signature = request.headers['X-Arbiter-Signature']
      unless signature
        render json: { error: 'missing signature' }, status: :unauthorized
        return
      end

      body = request.body.read
      request.body.rewind

      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
      unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
        render json: { error: 'invalid signature' }, status: :unauthorized
      end
    end

    def resolve_host(payload)
      match_field = Setting['arbiter_host_match_field'] || 'ipa_principal'

      case match_field
      when 'ipa_principal'
        principal = payload['ipa_principal'] || payload.dig('workload', 'ipa_principal')
        fqdn = principal&.split('@')&.first&.split('/')&.last
        Host::Managed.find_by(name: fqdn) if fqdn
      when 'fqdn'
        fqdn = payload['fqdn'] || payload.dig('workload', 'display_name')
        Host::Managed.find_by(name: fqdn)
      end
    end

    def refresh_host_status(host, record)
      status = host.get_status(ForemanArbiter::AttestationStatus)
      new_status = status.to_status(record.arbiter_state)
      host.get_status(ForemanArbiter::AttestationStatus).update(status: new_status) if new_status
      host.refresh_global_status!
    end
  end
end
