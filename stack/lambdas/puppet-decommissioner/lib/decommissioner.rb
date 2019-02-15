require 'net/https'
require 'uri'

class Decommissioner
  attr_reader :auth_cert, :auth_key, :pe_server

  def initialize(pe_server, auth_cert, auth_key)
    @pe_server = pe_server
    @auth_cert = OpenSSL::X509::Certificate.new(auth_cert)
    @auth_key  = OpenSSL::PKey::RSA.new(auth_key)
    raise "auth_key is not the correct private key for auth_cert" unless @auth_cert.check_private_key(@auth_key)
  end

  def decommission(hostname)
    [].tap do |result|
      result << request(
        method: :Put, 
        path: "/puppet-ca/v1/certificate_status/#{hostname}", 
        headers: { 'Content-Type': 'text/pson' }, 
        body: { desired_state: "revoked" }
      )

      result << request(
        method: :Delete, 
        path: "/puppet-ca/v1/certificate_status/#{hostname}", 
        headers: { Accept: 'pson' }
      )
    end
  end

  private

  def http
    @https ||= Net::HTTP.new(uri.host, uri.port).tap do |result|
      result.use_ssl = true
      result.verify_mode = OpenSSL::SSL::VERIFY_NONE
      result.cert = auth_cert
      result.key  = auth_key
    end
  end

  def request(method:, path:, headers: {}, body: nil)
    req = Net::HTTP.const_get(method).new(path)
    headers.each_pair do |header, value|
      req[header] = value
    end
    req.body = body&.to_json
    response = http.request(req)
    [req.method, path, response.code, response.message, response.body]
  end

  def uri
    @uri ||= URI(pe_server)
  end
end