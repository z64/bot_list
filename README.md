# bot_list

A shard for managing your Crystal bot's listings on multiple bot listing providers.

Write your own, or get started right away with https://discordbots.org or https://discord.bots.gg.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  bot_list:
    github: z64/bot_list
```

## Usage

```crystal
require "bot_list"

bot_list = BotList::Client.new(discord_client)

# Add some stock providers:
bot_list.add_provider("discordbots.org")
bot_list.add_provider("discord.bots.gg")

# Create a custom provider by implementing `name` and `update(cache)`:
class MyBotList < BotList::Provider
  def name
    "my custom bot listing"
  end

  def update(cache)
    payload = {guilds: cache.guilds.size}.to_json
    headers = HTTP::Headers{
      "Authorization" => ENV["MYBOTLIST_TOKEN"],
      "Content-Type": "application/json"
    }
    client_id = cache.resolve_current_user.id
    HTTP::Client.post("https://mybots.com/api/bots/#{client_id}", headers, payload)
  end
end

bot_list.add_provider(MyBotList.new)

# Update every provider with our stats every minute:
bot_list.update_every(1.minute)

# Update any time on-demand:
bot_list.update
```

## Contributors

- [z64](https://github.com/z64) Zac Nowicki - creator, maintainer
