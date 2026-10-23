module ForemanArbiter
  class Engine < ::Rails::Engine
    engine_name 'foreman_arbiter'

    config.autoload_paths += Dir["#{config.root}/app/controllers"]
    config.autoload_paths += Dir["#{config.root}/app/models"]

    initializer 'foreman_arbiter.register_plugin', before: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_arbiter do
        requires_foreman '>= 3.9'

        # -- Permissions --
        security_block :foreman_arbiter do
          permission :view_attestation,
                     { 'foreman_arbiter/hosts' => [:attestation_tab],
                       'foreman_arbiter/dashboard' => [:index],
                       'api/v2/foreman_arbiter/attestation' => [:index, :show] },
                     resource_type: 'Host'
          permission :manage_attestation,
                     { 'foreman_arbiter/webhook_receiver' => [:receive],
                       'foreman_arbiter/settings' => [:index, :update] },
                     resource_type: 'Host'
        end

        # -- Roles --
        role 'Attestation Viewer', [:view_attestation]
        role 'Attestation Manager', [:view_attestation, :manage_attestation]

        # -- Menu items --
        sub_menu :top_menu, :attestation_menu, after: :compliance_menu,
                 caption: N_('Attestation') do
          menu :top_menu, :attestation_dashboard,
               caption: N_('Dashboard'),
               url_hash: { controller: 'foreman_arbiter/dashboard', action: :index }
        end

        # -- Host detail tab --
        extend_page 'hosts/show' do |cx|
          cx.add_pagelet :main_tabs,
                         name: N_('Attestation'),
                         partial: 'foreman_arbiter/hosts/attestation_tab'
        end

        # -- Settings --
        settings do
          category :arbiter, N_('Arbiter Hub') do
            setting 'arbiter_hub_url',
                    type: :string,
                    default: '',
                    full_name: N_('Arbiter Hub API URL'),
                    description: N_('Base URL of the Arbiter Hub API (e.g., https://hub.example.com:8400)')
            setting 'arbiter_webhook_secret',
                    type: :string,
                    default: '',
                    full_name: N_('Webhook HMAC Secret'),
                    description: N_('Shared secret for HMAC-SHA256 webhook signature verification')
            setting 'arbiter_host_match_field',
                    type: :string,
                    default: 'ipa_principal',
                    full_name: N_('Host Match Field'),
                    description: N_('Arbiter Hub field to match against Satellite hosts (ipa_principal or fqdn)')
          end
        end
      end
    end

    config.to_prepare do
      Host::Managed.include ForemanArbiter::HostExtensions if defined?(Host::Managed)
      Foreman::Plugin.find(:foreman_arbiter).register_custom_status(ForemanArbiter::AttestationStatus)
    end
  end
end
