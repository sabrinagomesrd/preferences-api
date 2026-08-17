# frozen_string_literal: true

module V1
  module Preferences
    # Lista camadas humanas sem mesclar — equivalente conceitual a GET /presentation/raw.
    class RawController < ApplicationController
      def show
        records = Preference.for_account(current_platform_account_id)
          .singletons
          .where(
            resource_origin: params.require(:resource_origin),
            resource_key: params.require(:resource_key),
            surface: params.require(:surface),
            preference_type: params.require(:type)
          )
          .order(Arel.sql("CASE scope WHEN 'account' THEN 1 WHEN 'team' THEN 2 WHEN 'user' THEN 3 END"))

        if params[:context_host].present?
          records = records.where(context_host: params[:context_host])
        end

        render json: {
          data: records.map(&:as_api_json),
          meta: {
            note: "system layer is not stored here; provide it to /resolved as base"
          }
        }
      end
    end
  end
end
