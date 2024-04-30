#!/opt/puppetlabs/puppet/bin/ruby

# Dependencies
require 'net/https'
require 'uri'
require 'json'
require 'optparse'
require 'base64'

def parse_options()
  # Get arguments from CLI
  options = {}
  help = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0}"
    opts.on('-o [encrypt|decrypt]', '--operation [encrypt|decrypt]', "Operation: encrypt or decrypt") do |o|
      options[:operation] = o
    end
    opts.on('-a [algorithm]', '--algorithm [algorithm]', "AKMS algorithm - only RSA types supported. Default: RSA1_5") do |a|
      options[:algorithm] = a
    end
    opts.on('-s [string]', '--string [string]', "String to encrypt/decrypt") do |s|
      options[:string] = s
    end
    opts.on('-k [azure-key-url]', '--key [azure-key-url]', "URL for the Azure key - ex: https://testvault.vault.azure.net/keys/test-key/12345") do |k|
      options[:key] = k
    end
    opts.on('-h', '--help', 'Display this help') do
      puts opts
      exit
    end
  end
  help.parse!
  return options, help
end

def validate_options(options, help)
  # Validate arguments
  operation = options[:operation]
  algorithm = options[:algorithm] || 'RSA1_5'
  string = options[:string]
  key = options[:key]

  unless ['encrypt', 'decrypt'].include? operation 
    puts "ERROR: only operations allowed are encrypt and decrypt, not #{operation}"
    puts help
    exit 2
  end

  if string.nil? or string.empty?
    puts 'ERROR: string is a required argument'
    puts help
    exit 2
  end

  if key.nil? or key.empty?
    puts 'ERROR: key is a required argument'
    puts help
    exit 2
  end

  unless key =~ URI::regexp
    puts "ERROR: #{url} is not a valid key URL"
    puts help
    exit 2
  end

  return operation, algorithm, string, key
end

def get_token(scope)
  metadata_uri = URI('http://169.254.169.254')
  connection = Net::HTTP.new(metadata_uri.host, metadata_uri.port)
  resource = "/metadata/identity/oauth2/token?api-version=2018-02-01&resource=#{scope}"
  header = { 'Metadata' => 'true' }
  request = Net::HTTP::Get.new(resource, header)

  response = connection.request(request)
  body = JSON.parse(response.body)

  raise StandardError, "Azure returned an error code #{response.code} instead of a token for #{scope}" unless body['access_token']

  body['access_token']
end

def http_client(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 10
  http.write_timeout = 10
  http.open_timeout = 10

  http
end

def request(uri, string, algorithm)
  token     = get_token('https%3A%2F%2Fvault.azure.net')
  header    = { 'Authorization' => "Bearer #{token}" }

  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = { 'alg' => algorithm, 'value' => string }.to_json
  request.content_type = 'application/json'

  request
end

def crypt(operation, string, key, algorithm)
  uri         = URI("#{key}/#{operation}?api-version=7.5")
  http_client = http_client(uri)
  string.chomp!

  # Pass encoded value only during encrypt
  value = operation == "encrypt" ? Base64.strict_encode64(string).chomp : string

  request = request(uri, value, algorithm)

  begin
    response = http_client.request(request)
  rescue Net::OpenTimeout
    raise StandardError, 'HTTP client timed out while trying to access key'
  end

  case response.code
  when '200'
    # All good - read the body
    body = JSON.parse(response.body)
    if operation == "encrypt"
      body['value']
    else
      Base64.decode64(body['value'])
    end
  when '401'
    raise StandardError, 'Unauthorized to access key'
  when '403'
    raise StandardError, 'Cannot access key'
  when '404'
    raise StandardError, 'Key not found'
  else
    # Catch all other errors
    raise StandardError, JSON.parse(response.body)
  end
end

# Main script
# Set variables
options, help = parse_options()
operation, algorithm, string, key = validate_options(options, help)

value = crypt(operation, string, key, algorithm)

puts value
exit 0
