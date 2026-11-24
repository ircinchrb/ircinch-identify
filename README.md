# IRCinch Identify

## Description

`ircinch-identify` signs your IRCinch bot in to IRC services automatically
when it connects. It supports NickServ, UserServ, DALnet, QuakeNet, and KreyNet.

## Installation

The gem requires Ruby 3.3 or newer and IRCinch 2.4.6 or newer.

### RubyGems

```sh
gem install ircinch-identify
```

### Bundler

Add the plugin to your `Gemfile` and run `bundle install`.

```ruby
gem "ircinch-identify", require: false
```

To use a local checkout, add `path: "../ircinch-identify"` to the gem entry
and adjust the path to match your checkout.

## Example

Load `ircinch` first, then require the plugin and add `Cinch::Plugins::Identify`
to your bot's plugin list. This example uses NickServ over TLS. Set `IRC_SERVER`
and `IRC_SERVICES_PASSWORD` in the bot's environment, and use your own nickname,
services account, and the network's TLS port.

```ruby
require "ircinch"
require "cinch/plugins/identify"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = ENV.fetch("IRC_SERVER")
    c.port = 6697
    c.ssl.use = true
    c.ssl.verify = true
    c.nick = "example_bot"
    c.plugins.plugins = [Cinch::Plugins::Identify]
    c.plugins.options[Cinch::Plugins::Identify] = {
      type: :nickserv,
      username: "my_account",
      password: ENV.fetch("IRC_SERVICES_PASSWORD")
    }
  end
end

bot.start
```

For help with bot setup, see the [IRCinch Getting Started guide](https://github.com/ircinchrb/ircinch/blob/main/docs/getting_started.md).

## Configuration

Set `:type` to the authentication method your network supports.

| Type | Service and command |
| --- | --- |
| `:nickserv` | NickServ `identify`, with either an account name and password or a password alone |
| `:userserv` | UserServ `LOGIN` |
| `:dalnet` | DALnet NickServ `identify`, with a password alone |
| `:quakenet` | QuakeNet Q `auth`, which sends your password in the command |
| `:secure_quakenet` or `:challengeauth` | QuakeNet Q `CHALLENGEAUTH`, which sends an HMAC response |
| `:kreynet` | KreyNet K `LOGIN` |

- `:username` is your services account name. Omit it for password-only
  NickServ setups that identify the bot's current nickname, such as dancer-ircd.
- `:password` is your services account password.
- `:service_name` overrides the service target for `:nickserv` or `:userserv`.
  Their defaults are `"nickserv"` and `"UserServ"`, respectively. With a
  `nick@host` target, NickServ sends the login to `nick` and UserServ sends it
  to the full target. Both match replies by nickname.

The plugin emits `:identified` when it recognizes a success reply in NickServ,
UserServ, or QuakeNet mode. IRCinch handlers can listen with `on :identified`.

### Credential Logging

With IRCinch versions that support `sensitive: true`, the plugin redacts
commands containing passwords and QuakeNet `CHALLENGEAUTH` responses from
outgoing and send-error logs. Older IRCinch versions can still log these
commands, including on TLS connections.

### Libera.Chat and OFTC

Add the settings for your network inside the bot's `configure` block. IRCinch
handles SASL and TLS client certificates directly. Register
`Cinch::Plugins::Identify` only when using the NickServ fallback.

#### Libera.Chat

Use IRCinch's SASL PLAIN over TLS with your bot's registered account name and
password. Some Libera.Chat IP ranges require SASL during connection.
[Libera.Chat SASL guide](https://libera.chat/guides/sasl) ·
[Connection settings](https://libera.chat/guides/connect)

```ruby
c.server = "irc.libera.chat"
c.port = 6697
c.ssl.use = true
c.ssl.verify = true
c.sasl.mechanisms = [Cinch::SASL::Plain]
c.sasl.username = ENV.fetch("IRC_SERVICES_ACCOUNT")
c.sasl.password = ENV.fetch("IRC_SERVICES_PASSWORD")
```

For post-connect authentication, use the [NickServ example](#example) with
`IRC_SERVER=irc.libera.chat` and set `:username` to the bot's registered account
name. The plugin sends the account name followed by the password.
[Libera.Chat login guide](https://libera.chat/guides/registration#logging-in)

#### OFTC

Use CertFP for automatic identification. Register the certificate fingerprint
with NickServ and set `IRC_CLIENT_CERT` to the path of a PEM file containing
the client certificate and its RSA private key.
[OFTC CertFP guide](https://www.oftc.net/NickServ/CertFP/) ·
[Connection settings](https://www.oftc.net/)

```ruby
c.server = "irc.oftc.net"
c.port = 6697
c.ssl.use = true
c.ssl.verify = true
c.ssl.client_cert = ENV.fetch("IRC_CLIENT_CERT")
```

For password-based NickServ authentication, use the [NickServ example](#example)
with `IRC_SERVER=irc.oftc.net`, set `c.nick` to the bot's registered nickname,
and omit `:username` to send the password-only `IDENTIFY` command. OFTC's
two-argument form puts the password first.
[OFTC services FAQ](https://www.oftc.net/FAQ/Services/)

## Code of Conduct

Project discussions and contributions follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Contributing

Bug reports and pull requests are welcome. See the [changelog](CHANGELOG.md) for release history.

### Development

From a checkout of the repository, install the development dependencies and run
Minitest and Standard Ruby.

```sh
bundle install
bundle exec rake
```

Run `bundle exec rake test` to run the tests on their own. SimpleCov writes
its HTML report to `coverage/index.html`.

## License

The gem is available under the [MIT License](LICENSE.txt).
