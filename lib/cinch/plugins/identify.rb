# frozen_string_literal: true

require "openssl"

module Cinch
  module Plugins
    class Identify
      include Cinch::Plugin

      QUAKENET_SERVICE = "Q@CServe.quakenet.org"
      QUAKENET_CHALLENGE_TYPES = %i[secure_quakenet challengeauth].freeze
      QUAKENET_TYPES = [:quakenet, *QUAKENET_CHALLENGE_TYPES].freeze
      CHALLENGE_PATTERN = /^CHALLENGE (.+?) .+$/

      listen_to :connect, method: :identify
      def identify(_message)
        case config[:type]
        when :quakenet
          debug "Identifying with Q"
          identify_quakenet
        when :dalnet
          debug "Identifying with Nickserv on DALnet"
          identify_dalnet
        when :secure_quakenet, :challengeauth
          debug "Identifying with Q, using CHALLENGEAUTH"
          identify_secure_quakenet
        when :nickserv
          debug "Identifying with NickServ"
          identify_nickserv
        when :kreynet
          debug "Identifying with K on KreyNet"
          identify_kreynet
        when :userserv
          debug "Identifying with UserServ"
          identify_userserv
        else
          debug "Not going to identify with unknown type #{config[:type].inspect}"
        end
      end

      match(/^You are successfully identified as/, use_prefix: false, use_suffix: false, react_on: :private, method: :identified_nickserv)
      match(/^You are now identified for/, use_prefix: false, use_suffix: false, react_on: :private, method: :identified_nickserv)
      match(/^Password accepted - you are now recognized\./, use_prefix: false, use_suffix: false, react_on: :private, method: :identified_nickserv)
      match(/^Hasło przyjęte - jesteś zidentyfikowany/, use_prefix: false, use_suffix: false, react_on: :private, method: :identified_nickserv)
      def identified_nickserv(m)
        return unless config[:type] == :nickserv && m.user == User(nickserv_nick)

        debug "Identified with NickServ"
        @bot.handlers.dispatch(:identified, m)
      end

      match(CHALLENGE_PATTERN, use_prefix: false, use_suffix: false, react_on: :notice, method: :challengeauth)
      def challengeauth(m, challenge = nil)
        return unless QUAKENET_CHALLENGE_TYPES.include?(config[:type]) && m.user&.nick == "Q"

        challenge ||= m.message[CHALLENGE_PATTERN, 1]
        return unless challenge

        @bot.debug "Received challenge '#{challenge}'"
        username = config[:username].irc_downcase(:rfc1459)
        password_hash = OpenSSL::Digest::SHA256.hexdigest(config[:password][0, 10])
        key = OpenSSL::Digest::SHA256.hexdigest("#{username}:#{password_hash}")
        response = OpenSSL::HMAC.hexdigest("SHA256", key, challenge)
        send_sensitive(QUAKENET_SERVICE, "CHALLENGEAUTH #{username} #{response} HMAC-SHA-256")
      end

      match(/^You are now logged in as/, use_prefix: false, use_suffix: false, react_on: :notice, method: :identified_quakenet)
      def identified_quakenet(m)
        return unless QUAKENET_TYPES.include?(config[:type]) && m.user == User("q")

        debug "Identified with Q"
        @bot.handlers.dispatch(:identified, m)
      end

      match(/^You are now logged in as/, use_prefix: false, use_suffix: false, react_on: :notice, method: :identified_userserv)
      def identified_userserv(m)
        return unless config[:type] == :userserv && m.user == User(userserv_target.split("@", 2).first)

        debug "Identified with UserServ"
        @bot.handlers.dispatch(:identified, m)
      end

      private

      def send_sensitive(service, command)
        target = User(service)
        # Older IRCinch versions interpret a keyword hash as the positional NOTICE flag.
        if target.method(:send).parameters.include?([:key, :sensitive])
          target.send(command, sensitive: true)
        else
          target.send(command)
        end
      end

      def identify_dalnet
        send_sensitive("Nickserv@services.dal.net", "identify #{config[:password]}")
      end

      def identify_quakenet
        send_sensitive(QUAKENET_SERVICE, "auth #{config[:username]} #{config[:password]}")
      end

      def identify_secure_quakenet
        User(QUAKENET_SERVICE).send(:CHALLENGE)
      end

      def identify_nickserv
        username = config[:username]
        password = config[:password]
        command = if username
          "identify #{username} #{password}"
        else
          "identify #{password}"
        end
        send_sensitive(nickserv_nick, command)
      end

      def identify_kreynet
        send_sensitive("K!k@krey.net", "LOGIN #{config[:username]} #{config[:password]}")
      end

      def identify_userserv
        send_sensitive(userserv_target, "LOGIN #{config[:username]} #{config[:password]}")
      end

      def nickserv_nick
        (config[:service_name] || "nickserv").split("@", 2).first
      end

      def userserv_target
        config[:service_name] || "UserServ"
      end
    end
  end
end
