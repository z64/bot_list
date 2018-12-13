require "discordcr"
require "./provider"

module BotList
  VERSION = "0.1.0"

  # A client for managing a collection of bot list providers.
  class Client
    # The existing providers added to this client.
    getter providers : Array(Provider)

    def self.new(client : Discord::Client, logger : Logger = Logger.new(STDOUT))
      if cache = client.cache
        new(cache, logger)
      else
        raise "Client must have a cache set"
      end
    end

    def initialize(@cache : Discord::Cache, @logger : Logger = Logger.new(STDOUT))
      @providers = [] of Provider
      @logger.progname = "bot-list" if @logger.progname.nil?
    end

    # Adds an existing provider from one of `PROVIDERS` by name.
    #
    # ```
    # bot_list.add_provider("discordbots.org")
    # bot_list.add_provider("discord.bots.gg")
    # bot_list.add_provider("unknown") # Exception
    # ```
    def add_provider(name : String)
      if provider = PROVIDERS[name]?
        @providers << provider
      else
        raise "Unknown provider: #{name.inspect}. Available providers: #{PROVIDERS.keys.map(&.inspect).join(", ")}"
      end
    end

    # Adds an existing `Provider` instance to this client.
    def add_provider(provider : Provider)
      @providers << provider
    end

    # Iterates over this clients registered providers, and updates each
    # of them.
    def update
      @providers.each do |provider|
        response = provider.update(@cache)
        if response.success?
          log_success(provider, response)
        else
          log_error(provider, response)
        end
      rescue ex
        log_error(provider, ex)
      end
    end

    # Posts stats to all providers at the given `interval`.
    def update_every(interval : Time::Span)
      Discord.every(interval) do
        update
      end
    end

    # Debug logging for successful posts to a provider
    private def log_success(provider : Provider, response : HTTP::Client::Response)
      return unless @logger.debug?
      @logger.debug(<<-DOC)
      Posted stats to #{provider.name.inspect} (#{response.status_code} #{response.status_message})
      #{response.body? ? response.body : "(No body)"}
      DOC
    end

    # Logging for when a request was sent successfully, but the provider
    # service returned a failed response.
    private def log_error(provider : Provider, response : HTTP::Client::Response)
      @logger.error(<<-DOC)
      Failed to post stats to provider #{provider.name.inspect} (#{response.status_code} #{response.status_message})
      #{response.body? ? response.body : "(No body)"}
      DOC
    end

    # Logging for a general exception raised from a provider's request
    private def log_error(provider : Provider, ex : Exception)
      @logger.error(<<-DOC)
      Failed to post stats to provider #{provider.name.inspect} (#{ex.class}, #{ex.message})
      #{ex.backtrace}
      DOC
    end
  end
end