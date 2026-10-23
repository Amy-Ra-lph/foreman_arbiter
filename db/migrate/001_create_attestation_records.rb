class CreateAttestationRecords < ActiveRecord::Migration[7.0]
  def change
    return if table_exists?(:foreman_arbiter_attestation_records)

    create_table :foreman_arbiter_attestation_records do |t|
      t.references :host, null: false, foreign_key: { to_table: :hosts }
      t.string :arbiter_workload_id, null: false
      t.string :arbiter_state, null: false, default: 'UNKNOWN'
      t.string :composite_verdict, null: false, default: 'UNAVAILABLE'
      t.jsonb :per_backend, default: []
      t.jsonb :webhook_payload, default: {}
      t.datetime :received_at, null: false

      t.timestamps
    end

    add_index :foreman_arbiter_attestation_records,
              [:host_id, :received_at],
              order: { received_at: :desc },
              name: 'idx_arbiter_attestation_host_time'
    add_index :foreman_arbiter_attestation_records,
              :arbiter_workload_id,
              name: 'idx_arbiter_attestation_workload'
    add_index :foreman_arbiter_attestation_records,
              :composite_verdict,
              name: 'idx_arbiter_attestation_verdict'
  end
end
