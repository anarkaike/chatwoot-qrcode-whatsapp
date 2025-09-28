class Whatsapp::Providers::WhatsappZapiService < Whatsapp::Providers::BaseService
  class ProviderUnavailableError < StandardError; end

  API_BASE_PATH = 'https://api.z-api.io'.freeze

  def api_instance_path
    "#{API_BASE_PATH}/instances/#{whatsapp_channel.provider_config['instance_id']}"
  end

  def api_instance_path_with_token
    "#{api_instance_path}/token/#{whatsapp_channel.provider_config['token']}"
  end

  def api_headers
    { 'Content-Type' => 'application/json', 'Client-Token' => whatsapp_channel.provider_config['client_token'] }
  end

  def process_response(response)
    Rails.logger.error response.body unless response.success?
    response.success?
  end

  def send_template(phone_number, template_info); end

  def sync_templates; end

  def validate_provider_config?
    response = HTTParty.get(
      "#{api_instance_path_with_token}/status",
      headers: api_headers
    )

    process_response(response)
  end

  def setup_channel_provider
    response = HTTParty.put(
      "#{api_instance_path_with_token}/update-every-webhooks",
      headers: api_headers,
      body: {
        value: whatsapp_channel.inbox.callback_webhook_url,
        notifySentByMe: true
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    Channels::Whatsapp::ZapiQrCodeJob.perform_later(whatsapp_channel) if whatsapp_channel.provider_connection['connection'] == 'close'

    true
  end

  def disconnect_channel_provider
    response = HTTParty.get(
      "#{api_instance_path_with_token}/disconnect",
      headers: api_headers
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def qr_code_image
    response = HTTParty.get(
      "#{api_instance_path_with_token}/qr-code/image",
      headers: api_headers
    )

    whatsapp_channel.update_provider_connection!(connection: 'open') if response.parsed_response['connected']

    return unless process_response(response)

    response.parsed_response['value']
  end
end
