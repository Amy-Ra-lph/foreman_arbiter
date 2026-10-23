require 'test_helper'

class AttestationStatusTest < ActiveSupport::TestCase
  test 'maps HEALTHY to OK global status' do
    status = ForemanArbiter::AttestationStatus.new
    status.status = ForemanArbiter::AttestationStatus::HEALTHY
    assert_equal HostStatus::Global::OK, status.to_global
  end

  test 'maps FAILED to ERROR global status' do
    status = ForemanArbiter::AttestationStatus.new
    status.status = ForemanArbiter::AttestationStatus::FAILED
    assert_equal HostStatus::Global::ERROR, status.to_global
  end

  test 'maps ATTESTING to WARN global status' do
    status = ForemanArbiter::AttestationStatus.new
    status.status = ForemanArbiter::AttestationStatus::ATTESTING
    assert_equal HostStatus::Global::WARN, status.to_global
  end

  test 'to_status maps string states correctly' do
    status = ForemanArbiter::AttestationStatus.new
    assert_equal 0, status.to_status('HEALTHY')
    assert_equal 2, status.to_status('FAILED')
    assert_equal 2, status.to_status('REVOKED')
    assert_equal 1, status.to_status('STALE')
    assert_nil status.to_status('BOGUS')
  end

  test 'STATE_MAP covers all Arbiter Hub states' do
    expected_states = %w[HEALTHY ATTESTING STALE REGISTERED FAILED REVOKED UNDER_REMEDIATION]
    expected_states.each do |state|
      assert ForemanArbiter::AttestationStatus::STATE_MAP.key?(state),
             "STATE_MAP missing #{state}"
    end
  end
end
