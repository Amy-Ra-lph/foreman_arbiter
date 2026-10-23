module ForemanArbiter
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      has_many :attestation_records,
               class_name: 'ForemanArbiter::AttestationRecord',
               foreign_key: :host_id,
               dependent: :destroy
    end

    def latest_attestation
      attestation_records.order(received_at: :desc).first
    end

    def attestation_state
      latest_attestation&.arbiter_state || 'UNKNOWN'
    end
  end
end
