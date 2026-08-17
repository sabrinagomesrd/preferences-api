# frozen_string_literal: true

# Preferência humana persistida como *delta* (desvio), nunca como cópia integral da tela.
#
# Escopos graváveis nesta API: account | team | user
# O escopo `system` (padrão calculado) mora no Serviço de Metadados de Apresentação — fora desta POC.
#
# Cardinalidade:
# - singleton: uma definição ativa por identidade (cartão, arranjo…)
# - multi: várias instâncias no mesmo contexto (ex.: filtros salvos da Listagem)
class Preference < ApplicationRecord
  RESOURCE_ORIGINS = %w[platform_object product_entity].freeze
  SCOPES = %w[account team user].freeze
  CARDINALITIES = %w[singleton multi].freeze
  SURFACES = %w[
    cartao
    cartao_associado
    arranjo_perfil
    arranjo_painel
    config_formulario
    listagem
  ].freeze
  validates :uuid, presence: true, uniqueness: true
  validates :platform_account_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :resource_origin, inclusion: { in: RESOURCE_ORIGINS }
  validates :resource_key, :surface, :preference_type, :scope, :scope_ref, :cardinality, presence: true
  validates :scope, inclusion: { in: SCOPES }
  validates :cardinality, inclusion: { in: CARDINALITIES }
  validates :surface, inclusion: { in: SURFACES }
  validates :name, presence: true, if: -> { cardinality == "multi" }
  validate :system_scope_not_allowed
  validate :singleton_identity_unique, if: -> { cardinality == "singleton" }

  before_validation :ensure_uuid
  before_validation :normalize_blank_context

  scope :for_account, ->(platform_account_id) { where(platform_account_id: platform_account_id) }
  scope :singletons, -> { where(cardinality: "singleton") }
  scope :multi, -> { where(cardinality: "multi") }

  def identity_attributes
    {
      platform_account_id: platform_account_id,
      resource_origin: resource_origin,
      resource_key: resource_key,
      surface: surface,
      preference_type: preference_type,
      context_host: context_host,
      context_association: context_association,
      scope: scope,
      scope_ref: scope_ref
    }
  end

  def as_api_json
    {
      id: uuid,
      resource: {
        origin: resource_origin,
        key: resource_key
      },
      surface: surface,
      type: preference_type,
      context: context_payload,
      scope: scope,
      scope_ref: scope_ref,
      cardinality: cardinality,
      name: name,
      is_default: is_default,
      payload: payload,
      stale: stale,
      created_by: created_by,
      updated_at: updated_at&.iso8601
    }.compact
  end

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def normalize_blank_context
    self.context_host = context_host.presence
    self.context_association = context_association.presence
  end

  def context_payload
    return nil if context_host.blank? && context_association.blank?

    {
      host: context_host,
      association: context_association
    }.compact
  end

  def system_scope_not_allowed
    return unless scope == "system"

    errors.add(:scope, "system is owned by Presentation metadata, not Preferences")
  end

  def singleton_identity_unique
    conflict = self.class.singletons
      .where(identity_attributes)
      .where.not(id: id)
      .exists?

    errors.add(:base, "singleton already exists for this identity") if conflict
  end
end
