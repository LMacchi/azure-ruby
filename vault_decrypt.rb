#!/opt/puppetlabs/puppet/bin/ruby
require 'net/http'
require 'json'

if ARGV.length < 4 then
  puts "USAGE: #{$0} token key_id algorithm value"
  exit 1
end

# Set variables
token = ARGV[0]
key_id = ARGV[1]
algorithm = ARGV[2]
value = ARGV[3]
vault_api_version = "7.4"

# Encrypt
uri = URI("#{key_id}/decrypt?api-version=#{vault_api_version}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
header = { 'Authorization' => "Bearer #{token}" }
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = { 'alg' => algorithm, 'value' => value }.to_json
request.content_type = 'application/json'
response = http.request(request)

# Print secret
body = JSON.parse(response.body)
puts body['value']
