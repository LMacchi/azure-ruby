#!/opt/puppetlabs/puppet/bin/ruby
require 'uri'
require 'net/http'
require 'json'
require 'cgi'

if ARGV.length != 2 then
  puts "USAGE: #{$0} key app_config_resource"
  exit 1
end

key = ARGV[0]
resource = ARGV[1]
def get_token(scope)
  # Set variables
  metadata_uri = URI('http://169.254.169.254')
  escaped_scope = CGI.escape(scope).gsub("+", "%20")

  # Get token scoped to account via HTTP call
  connection = Net::HTTP.new(metadata_uri.host, metadata_uri.port)
  resource = "/metadata/identity/oauth2/token?api-version=2018-02-01&resource=#{scope}"
  header = { 'Metadata' => 'true' }
  request_and_headers = Net::HTTP::Get.new(resource, header)

  response = connection.request(request_and_headers)

  body = JSON.parse(response.body)

  body['access_token']
end

# Set variables
token = get_token(resource)
url = "#{resource}/kv?key=#{key}&api-version=1.0"

kv_uri = URI(url)

http = Net::HTTP.new(kv_uri.host, kv_uri.port)
http.use_ssl = true
header = { 'Authorization' => "Bearer #{token}", 'x-ms-version' => '2017-11-09' }
request = Net::HTTP::Get.new(kv_uri, header)
response = http.request(request)
content = JSON.parse response.body

puts content['items'][0]['value']
