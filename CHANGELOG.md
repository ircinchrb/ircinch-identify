# Changelog

## ircinch-identify 1.7.1 (unreleased)

- Forked `cinch-identify` as `ircinch-identify`. The gem requires IRCinch 2.4.6 or later and Ruby 3.3 or later. Load it with `require "cinch/plugins/identify"` and register `Cinch::Plugins::Identify`.
- Fixed the `:identified` event for custom NickServ targets in `nick@host` form. The plugin now uses the same nickname for the login command and for matching the reply.
- Reused the challenge captured by IRCinch when handling QuakeNet `CHALLENGEAUTH` notices. Success handlers check the configured authentication type before looking up the service user.
- Added test coverage for every authentication mode, the QuakeNet HMAC response, and the service replies that trigger `:identified`.
- Updated gem metadata and README.

## Original cinch-identify releases

Release dates come from RubyGems. Change summaries are based on the original repository's commit history. [RubyGems release archive](https://rubygems.org/gems/cinch-identify/versions) · [Original repository](https://github.com/cinchrb/cinch-identify)

### 1.7.0 (2015-03-10)

- Extended `:service_name` to NickServ. The plugin used the nickname portion of a `nick@host` target when sending the login command.
- Matched UserServ success replies by nickname when `:service_name` included a host.

### 1.6.0 (2014-05-03)

- Recognized the Polish-language NickServ success reply and emitted `:identified`.

### 1.5.1 (2013-11-15)

- Added the MIT license to the gem metadata.

### 1.5.0 (2013-09-25)

- Added the `:dalnet` authentication mode for password-only login to DALnet's NickServ.
- Recognized OFTC's NickServ success reply and emitted `:identified`.

### 1.4.1 (2012-12-29)

- Recognized Rizon's NickServ success reply and emitted `:identified`.
- Updated the credential logging warning to include UserServ.

### 1.4.0 (2012-12-10)

- Added account-based UserServ authentication with `:userserv`, a configurable `:service_name`, and an `:identified` event on success.
- Restricted QuakeNet challenge responses to the `:secure_quakenet` and `:challengeauth` modes.

### 1.3.1 (2012-11-06)

- Fixed the QuakeNet success handler so it receives the message and can emit `:identified`.

### 1.3.0 (2012-06-27)

- Added the `:identified` event for successful NickServ logins and a handler for success notices from QuakeNet Q.
- Added a debug message for unknown authentication types and fixed formatting in the README's loading example.

### 1.2.0 (2012-06-17)

- Added password-only NickServ authentication when `:username` is omitted, for networks that identify the current nickname.

### 1.1.2 (2012-03-24)

- Updated the runtime dependency to the stable Cinch 2.x series (`~> 2.0`).

### 1.1.1 (2012-03-06)

- Ported to Cinch `2.0.0.pre.2`, updated the QuakeNet notice matcher, and relaxed the runtime dependency to `>= 2.0.0.pre.2`.

### 1.1.0 (2012-03-04)

- Added KreyNet authentication with `:kreynet` and switched QuakeNet challenge handling to a notice matcher.

### 1.0.0 (2012-03-04)

- Switched the runtime dependency from Cinch 1.x to `2.0.0.pre.1`.

### 0.0.1 (2011-01-29)

- Released the plugin for Cinch 1.x with automatic NickServ and QuakeNet authentication. QuakeNet supported both `auth` and `CHALLENGEAUTH`.
