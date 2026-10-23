module ForemanArbiter
  class AttestationRecord < ApplicationRecord
    self.table_name = 'foreman_arbiter_attestation_records'

    belongs_to :host, class_name: 'Host::Managed'

    validates :host_id, presence: true
    validates :arbiter_workload_id, presence: true
    validates :composite_verdict, inclusion: { in: %w[PASS FAIL UNAVAILABLE ERROR] }

    serialize :per_backend, coder: JSON
    serialize :webhook_payload, coder: JSON

    scope :latest_per_host, -> {
      select('DISTINCT ON (host_id) *').order('host_id, received_at DESC')
    }

    scope :failed, -> { where(composite_verdict: 'FAIL') }
    scope :healthy, -> { where(composite_verdict: 'PASS') }

    def passed?
      composite_verdict == 'PASS'
    end

    def failed?
      composite_verdict == 'FAIL'
    end
  end
end
