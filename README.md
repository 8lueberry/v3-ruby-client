# Zumata

For interaction with the Zumata API 3.0
[Documentation](http://docs.api-v3.zumata.com)

### Installation
`gem install zumata_v3`

### Configuration
```
API_KEY = "YOUR API KEY"
API_URL = "https://test.api-v3.zumata.com

ZumataV3.configure do |config|
  config.api_url = API_URL
  config.api_key = API_KEY
end
```

## Contributing

1. Fork it ( https://github.com/Zumata/v3-ruby-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
