module ForemanArbiter
  class AttestationStatus < HostStatus::Status
    # Arbiter Hub workload states mapped to Foreman status values.
    # Foreman uses 0 = OK, 1 = Warning, 2 = Error for sub-status display.
    HEALTHY          = 0
    ATTESTING        = 1
    STALE            = 1
    REGISTERED       = 1
    FAILED           = 2
    REVOKED          = 2
    UNDER_REMEDIATION = 1
    UNKNOWN          = nil

    STATE_MAP = {
      'HEALTHY'            => HEALTHY,
      'ATTESTING'          => ATTESTING,
      'STALE'              => STALE,
      'REGISTERED'         => REGISTERED,
      'FAILED'             => FAILED,
      'REVOKED'            => REVOKED,
      'UNDER_REMEDIATION'  => UNDER_REMEDIATION,
    }.freeze

    def self.status_name
      N_('Attestation')
    end

    def to_global(options = {})
      case status
      when HEALTHY
        HostStatus::Global::OK
      when ATTESTING, STALE, REGISTERED, UNDER_REMEDIATION
        HostStatus::Global::WARN
      when FAILED, REVOKED
        HostStatus::Global::ERROR
      else
        HostStatus::Global::OK
      end
    end

    def to_label(_options = {})
      case status
      when HEALTHY
        N_('Attestation: Healthy')
      when ATTESTING
        N_('Attestation: In Progress')
      when FAILED, REVOKED
        N_('Attestation: Failed')
      else
        N_('Attestation: Unknown')
      end
    end

    def to_status(arbiter_state)
      STATE_MAP.fetch(arbiter_state.to_s.upcase, UNKNOWN)
    end

    def relevant?(_options = {})
      host_attestation_record.present?
    end

    private

    def host_attestation_record
      ForemanArbiter::AttestationRecord
        .where(host_id: host_id)
        .order(received_at: :desc)
        .first
    end
  end
end
