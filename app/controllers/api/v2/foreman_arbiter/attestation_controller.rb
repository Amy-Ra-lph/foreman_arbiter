module Api
  module V2
    module ForemanArbiter
      class AttestationController < V2::BaseController
        before_action :find_host

        api :GET, '/api/v2/hosts/:host_id/attestation', N_('Show attestation status for a host')
        param :host_id, :identifier, required: true

        def show
          @records = ::ForemanArbiter::AttestationRecord
                       .where(host_id: @host.id)
                       .order(received_at: :desc)
                       .limit(20)
          @latest = @records.first

          render json: {
            host_id: @host.id,
            host_name: @host.name,
            current_state: @latest&.arbiter_state || 'UNKNOWN',
            composite_verdict: @latest&.composite_verdict,
            last_attested_at: @latest&.received_at,
            per_backend: @latest&.per_backend || [],
            history: @records.map { |r|
              {
                id: r.id,
                state: r.arbiter_state,
                verdict: r.composite_verdict,
                received_at: r.received_at,
                per_backend: r.per_backend,
              }
            },
          }
        end

        private

        def find_host
          @host = Host::Managed.authorized(:view_hosts).find(params[:host_id])
        rescue ActiveRecord::RecordNotFound
          not_found
        end
      end
    end
  end
end
