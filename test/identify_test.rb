# frozen_string_literal: true

require_relative "test_helper"
require "cinch/plugins/identify"

class IdentifyTest < Minitest::Test
  def setup
    @bot = Cinch::Bot.new
    loggers = @bot.loggers
    loggers.clear
    def loggers.exception(error)
      raise error
    end

    # Wait for handlers, including any nested :identified dispatch, before asserting.
    handlers = @bot.handlers
    def handlers.dispatch(...)
      super.each(&:join)
    end

    @commands = []
    commands = @commands
    @bot.irc.define_singleton_method(:send) { |line| commands << line }
    @bot.irc.setup
    @bot.irc.parse(":irc.example.test 001 bot :Welcome")
    @bot.sync(:user, "bot", true)
    @bot.sync(:host, "localhost", true)

    plugin_class = Cinch::Plugins::Identify
    @bot.plugins.register_plugins([plugin_class])
    @options = @bot.config.plugins.options[plugin_class]
    @options[:username] = "account"
    @options[:password] = "test-password"
    @identified = []
    identified = @identified
    @bot.on(:identified) { |message| identified << message }
  end

  def test_connect_sends_the_command_for_each_authentication_type
    expected_commands = {
      dalnet: "PRIVMSG Nickserv@services.dal.net :identify test-password",
      quakenet: "PRIVMSG Q@CServe.quakenet.org :auth account test-password",
      secure_quakenet: "PRIVMSG Q@CServe.quakenet.org :CHALLENGE",
      challengeauth: "PRIVMSG Q@CServe.quakenet.org :CHALLENGE",
      nickserv: "PRIVMSG nickserv :identify account test-password",
      kreynet: "PRIVMSG K!k@krey.net :LOGIN account test-password",
      userserv: "PRIVMSG UserServ :LOGIN account test-password"
    }

    expected_commands.each do |type, command|
      @options[:type] = type
      connect
      assert_equal [command], @commands, type.to_s
    end
  end

  def test_connect_skips_missing_or_unknown_authentication_types
    [nil, :unknown].each do |type|
      @options[:type] = type
      connect
      assert_empty @commands
    end
  end

  def test_nickserv_supports_a_custom_service_and_password_only_authentication
    @options[:type] = :nickserv
    @options[:service_name] = "Services@irc.example.test"
    @options.delete(:username)

    connect

    assert_equal ["PRIVMSG Services :identify test-password"], @commands

    receive(":Services!service@irc.example.test PRIVMSG bot :You are now identified for account")

    assert_equal ["You are now identified for account"], @identified.map(&:message)
  end

  def test_userserv_uses_the_full_configured_target_to_log_in
    @options[:type] = :userserv
    @options[:service_name] = "Accounts@irc.example.test"

    connect

    assert_equal ["PRIVMSG Accounts@irc.example.test :LOGIN account test-password"], @commands
  end

  def test_secure_quakenet_responds_to_q_with_the_expected_hmac
    @options[:username] = 'TEST[USER]\^'
    @options[:password] = "0123456789ignored"
    # Known response for challenge "test-challenge", user "test{user}|~", and password "0123456789".
    response = "0a0eb77ea6464bb94a9207fdc059c53aeddcdb60e7d03a71af95dc66d6c943ff"
    challenge_notice = ":Q!service@CServe.quakenet.org NOTICE bot :CHALLENGE test-challenge HMAC-SHA-256"
    expected_command = "PRIVMSG Q@CServe.quakenet.org :CHALLENGEAUTH test{user}|~ #{response} HMAC-SHA-256"

    %i[secure_quakenet challengeauth].each do |type|
      @options[:type] = type
      @commands.clear
      receive(challenge_notice)

      assert_equal [expected_command], @commands, type.to_s
    end

    @commands.clear
    @bot.plugins.fetch(0).challengeauth(Cinch::Message.new(challenge_notice, @bot))

    assert_equal [expected_command], @commands
  end

  def test_secure_quakenet_ignores_challenges_with_the_wrong_sender_or_message_format
    @options[:type] = :secure_quakenet

    receive(":Other!service@irc.example.test NOTICE bot :CHALLENGE test-challenge HMAC-SHA-256")
    receive(":irc.example.test NOTICE bot :CHALLENGE test-challenge HMAC-SHA-256")
    receive(":Q!service@CServe.quakenet.org PRIVMSG bot :CHALLENGE test-challenge HMAC-SHA-256")
    receive(":Q!service@CServe.quakenet.org NOTICE bot :CHALLENGE test-challenge")

    assert_empty @commands
  end

  def test_plain_quakenet_ignores_challenges
    @options[:type] = :quakenet

    receive(":Q!service@CServe.quakenet.org NOTICE bot :CHALLENGE test-challenge HMAC-SHA-256")

    assert_empty @commands
  end

  def test_nickserv_dispatches_identified_for_each_success_message
    @options[:type] = :nickserv
    replies = [
      "You are successfully identified as account",
      "You are now identified for account",
      "Password accepted - you are now recognized.",
      "Hasło przyjęte - jesteś zidentyfikowany"
    ]

    replies.each { |reply| receive(":NickServ!service@irc.example.test PRIVMSG bot :#{reply}") }

    assert_equal replies, @identified.map(&:message)
  end

  def test_nickserv_accepts_the_configured_service_and_ignores_other_senders_and_channels
    @options[:type] = :nickserv
    @options[:service_name] = "Services"
    reply = "You are now identified for account"
    receive(":NickServ!service@irc.example.test PRIVMSG bot :#{reply}")
    receive(":Services!service@irc.example.test PRIVMSG #channel :#{reply}")
    assert_empty @identified

    receive(":Services!service@irc.example.test PRIVMSG bot :#{reply}")

    assert_equal [reply], @identified.map(&:message)
  end

  def test_quakenet_dispatches_identified_for_each_quakenet_type
    %i[quakenet secure_quakenet challengeauth].each do |type|
      @options[:type] = type
      @identified.clear
      receive(":Q!service@CServe.quakenet.org NOTICE bot :You are now logged in as account")

      assert_equal ["You are now logged in as account"], @identified.map(&:message), type.to_s
    end
  end

  def test_quakenet_ignores_success_messages_from_other_senders_or_in_privmsgs
    @options[:type] = :quakenet
    reply = "You are now logged in as account"

    receive(":Other!service@irc.example.test NOTICE bot :#{reply}")
    receive(":Q!service@CServe.quakenet.org PRIVMSG bot :#{reply}")

    assert_empty @identified
  end

  def test_userserv_accepts_the_default_and_configured_service_nicks
    @options[:type] = :userserv
    receive(":UserServ!service@irc.example.test NOTICE bot :You are now logged in as account")

    @options[:service_name] = "Accounts@irc.example.test"
    receive(":UserServ!service@irc.example.test NOTICE bot :You are now logged in as account")
    receive(":Accounts!service@irc.example.test NOTICE bot :You are now logged in as account")

    assert_equal %w[UserServ Accounts], @identified.map { |message| message.user.nick }
  end

  def test_success_messages_for_unconfigured_services_do_not_dispatch_identified
    @options[:type] = :dalnet

    receive(":NickServ!service@irc.example.test PRIVMSG bot :You are now identified for account")
    receive(":Q!service@CServe.quakenet.org NOTICE bot :You are now logged in as account")
    receive(":UserServ!service@irc.example.test NOTICE bot :You are now logged in as account")

    assert_empty @identified
  end

  private

  def connect
    @commands.clear
    @bot.irc.setup
    receive(":irc.example.test 376 bot :End of MOTD")
  end

  def receive(line)
    @bot.irc.parse(line)
  end
end
