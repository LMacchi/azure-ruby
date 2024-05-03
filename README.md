# Ruby + Azure APIs

Azure recommendation is to use https libraries to contact their APIs directly instead of using language specific libraries.

This repo contains Ruby scripts to:
- Get an API token
- Get a vault secret
- Get a blob file
- Encrypt and decrypt data with vault key

## Examples

### Get token for storage account

```
$ ruby get_token.rb "https%3A%2F%2Ftestbucket.blob.core.windows.net%2F"
```

### Get token for vault

```
$ ruby get_token.rb "https%3A%2F%2Fvault.azure.net"
```

### Get vault secret

```
$ token=$(ruby get_token.rb "https%3A%2F%2Fvault.azure.net")
$ ruby vault_get_secret.rb $token hieratestvault encrypted-test
Secret https://testvault.vault.azure.net/secrets/encrypted-test/1234 has a value of hunter2
```

### Get blob file

```
$ token=$(ruby get_token.rb "https%3A%2F%2Ftestbucket.blob.core.windows.net%2F")
$ ruby get_blob_file.rb $token testbucket "default/test_file.txt"
AAAAAAAAAAAAAAA
```

### Encrypt with AKMS key

```
ruby vault_encrypt.rb $token "https://testvault.vault.azure.net/keys/test-key/12345" "RSA1_5" "meow"
<encrypted string>
```

### Decrypt with AKMS key

```
ruby vault_decrypt.rb $token "https://testvault.vault.azure.net/keys/test-key/12345" "RSA1_5" $encrypted_string
meow
```

### Encrypt/Decrypt with AKMS key (fancier)

```
# Encrypt
enc=$(ruby vault_encrypt_decrypt.rb -o encrypt -s meow -k $key_url)

# Decrypt
ruby vault_encrypt_decrypt.rb -o decrypt -s $enc -k $key_url
meow
```

### Retrieve a key from Azure App Configuration

```
ruby app_config_get_kv_value.rb $key $app
{
  "foo": "bar",
  "cat": "meow",
}
```
