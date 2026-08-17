# frozen_string_literal: true

# Equivalente conceitual ao /health_check da Objects API (microservice-toolkit).
# Na POC, endpoint mínimo para readiness local.
class HealthController < ActionController::API
  def show
    render json: { status: "ok", service: "preferences-api", mode: "poc", store: "postgres" }
  end
end
