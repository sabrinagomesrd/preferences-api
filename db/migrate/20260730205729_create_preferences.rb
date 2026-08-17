# frozen_string_literal: true

class CreatePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :preferences do |t|
      t.string :uuid, null: false
      t.integer :platform_account_id, null: false
      t.string :resource_origin, null: false
      t.string :resource_key, null: false
      t.string :surface, null: false
      t.string :preference_type, null: false
      # context é opcional no contrato (só superfície embutida). Ausente = NULL.
      # Unicidade do singleton sem context fica no model (`singleton_identity_unique`):
      # o unique parcial abaixo não trata dois NULL como iguais.
      t.string :context_host
      t.string :context_association
      t.string :scope, null: false
      t.string :scope_ref, null: false
      t.string :cardinality, null: false, default: "singleton"
      t.string :name
      t.boolean :is_default, null: false, default: false
      t.jsonb :payload, null: false, default: {}
      t.boolean :stale, null: false, default: false
      t.string :created_by

      t.timestamps
    end

    add_index :preferences, :uuid, unique: true
    add_index :preferences,
              %i[
                platform_account_id
                resource_origin
                resource_key
                surface
                preference_type
                context_host
                context_association
                scope
                scope_ref
              ],
              unique: true,
              where: "cardinality = 'singleton'",
              name: "index_preferences_singleton_identity"
    add_index :preferences,
              %i[platform_account_id resource_key surface scope scope_ref],
              name: "index_preferences_lookup"
  end
end
