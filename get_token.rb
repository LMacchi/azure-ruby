#!/opt/puppetlabs/puppet/ruby
require 'uri'
require 'net/http'
require 'json'

if ARGV.length != 1 then
  puts "USAGE: #{$0} scope"
  exit 1
end

# Set variables
scope = ARGV[0]
metadata_uri = URI('http://169.254.169.254')

# Get token scoped to account via HTTP call
connection = Net::HTTP.new(metadata_uri.host, metadata_uri.port)
resource = "/metadata/identity/oauth2/token?api-version=2018-02-01&resource=#{scope}"
header = { 'Metadata' => 'true' }
request_and_headers = Net::HTTP::Get.new(resource, header)

response = connection.request(request_and_headers)

body = JSON.parse(response.body)

puts body['access_token']
