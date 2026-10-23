module ForemanArbiter
  class DashboardController < ApplicationController
    before_action :find_resource, only: [:show]

    def index
      @records = AttestationRecord.latest_per_host.includes(:host)
      @summary = {
        healthy: @records.count(&:passed?),
        failed: @records.count(&:failed?),
        total: @records.size,
      }
    end
  end
end
