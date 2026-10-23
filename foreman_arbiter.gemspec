require File.expand_path('lib/foreman_arbiter/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_arbiter'
  s.version     = ForemanArbiter::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Amy Ralph']
  s.email       = ['afarley@redhat.com']
  s.homepage    = 'https://github.com/Amy-Ra-lph/foreman_arbiter'
  s.summary     = 'Foreman plugin for Arbiter Hub attestation integration'
  s.description = 'Surfaces workload attestation status from Arbiter Hub in Foreman/Satellite. ' \
                  'Receives HMAC-signed webhooks on state transitions, maintains per-host attestation ' \
                  'sub-status, and provides a host tab with attestation history and per-backend verdicts.'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'README.md']

  s.required_ruby_version = '>= 3.1'

  s.add_dependency 'openssl', '>= 3.0'
end
