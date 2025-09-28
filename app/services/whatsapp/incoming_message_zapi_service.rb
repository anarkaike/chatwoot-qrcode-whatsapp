class Whatsapp::IncomingMessageZapiService < Whatsapp::IncomingMessageBaseService
  include Whatsapp::ZapiHandlers::ConnectedCallback

  def perform
    return if processed_params[:type].blank?

    event_prefix = processed_params[:type].underscore
    method_name = "process_#{event_prefix}"
    if respond_to?(method_name, true)
      send(method_name)
    else
      # Rails.logger.warn "Z-API unsupported event: #{processed_params[:type]}"
      Rails.logger.warn "Z-API unsupported event: #{processed_params.inspect}"
    end
  end
end
