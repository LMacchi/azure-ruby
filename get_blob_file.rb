#!/opt/puppetlabs/puppet/ruby
require 'uri'
require 'net/http'

if ARGV.length != 3 then
  puts "USAGE: #{$0} token account path"
  exit 1
end

# Set variables
token = ARGV[0]
account = ARGV[1]
blob_path = ARGV[2]

url = "https://#{account}.blob.core.windows.net/#{blob_path}"

puts "DEBUG: Attempting to connect to #{url}"

blob_uri = URI(url)

http = Net::HTTP.new(blob_uri.host, blob_uri.port)
http.use_ssl = true
header = { 'Authorization' => "Bearer #{token}", 'x-ms-version' => '2017-11-09' }
request = Net::HTTP::Get.new(blob_uri, header)
response = http.request(request)
code = response.code
content = response.body

puts "DEBUG: Response code is #{code} and the unparsed content is:\n#{content}"
