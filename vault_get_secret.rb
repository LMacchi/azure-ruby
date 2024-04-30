#!/opt/puppetlabs/puppet/bin/ruby
require 'net/http'
require 'json'

if ARGV.length < 3 then
  puts "USAGE: #{$0} token vault_name secret_name [secret_version]"
  puts "USAGE: #{$0} secret_version is optional - will use latest if left empty"
  exit 1
end

# Set variables
token = ARGV[0]
vault_name = ARGV[1]
secret_name = ARGV[2]
secret_version = ARGV[3].nil? ? "" : ARGV[3]

version_parameter = secret_version.empty? ? secret_version : "/#{secret_version}"
vault_api_version = "7.4"

# Get secret
uri = URI("https://#{vault_name}.vault.azure.net/secrets/#{secret_name}#{version_parameter}?api-version=#{vault_api_version}")
req = Net::HTTP::Get.new(uri.request_uri)
req['Authorization'] = "Bearer #{token}"
res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(req)
end

# Print secret
body = JSON.parse(res.body)
puts "Secret #{body['id']} has a value of #{body['value']}"
