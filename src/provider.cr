module BotList
  # A provider is a class that describes a bot list provider.
  abstract class Provider
    # This providers name, used for identification.
    def name
      self.class.to_s.underscore
    end

    # Updates this provider with statistics gathered from the given
    # `cache`.
    abstract def update(cache : Discord::Cache)
  end

  # Collection of well-known providers.
  PROVIDERS = {
    "discordbots.org" => DBotsDotOrgProvider.new,
    "discord.bots.gg" => DBotsDotGGProvider.new,
  }

  # Provider for https://discordbots.org. If no token is passed to
  # the constructor, it will be read from `ENV["DBOTSDOTORG_TOKEN"]`.
  class DBotsDotOrgProvider < Provider
    def initialize(@token : String? = nil)
    end

    def token
      @token ||= ENV["DBOTSDOTORG_TOKEN"]
    end

    def name
      "discordbots.org"
    end

    def update(cache : Discord::Cache)
      payload = {server_count: cache.guilds.size}.to_json
      headers = HTTP::Headers{
        "Authorization" => token,
        "Content-Type":    "application/json",
      }
      HTTP::Client.post(
        "https://discordbots.org/api/bots/stats",
        headers,
        payload
      )
    end
  end

  # Provider for https://discord.bots.gg. If no token is passed to
  # the constructor, it will be read from `ENV["BOTSGG_TOKEN"]`.
  class DBotsDotGGProvider < Provider
    def initialize(@token : String? = nil)
    end

    def token
      @token ||= ENV["DBOTSGG_TOKEN"]
    end

    def name
      "discord.bots.gg"
    end

    def update(cache : Discord::Cache)
      payload = {guildCount: cache.guilds.size}.to_json
      headers = HTTP::Headers{
        "Authorization" => token,
        "Content-Type":    "application/json",
      }
      client_id = cache.resolve_current_user.id
      HTTP::Client.post(
        "https://discord.bots.gg/api/v1/bots/#{client_id}/stats",
        headers,
        payload
      )
    end
  end
end
