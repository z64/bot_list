require "./spec_helper"

private class TestProvider < BotList::Provider
  getter called : Bool = false

  def update(cache : Discord::Cache)
    @called = true
    HTTP::Client::Response.new(204, nil)
  end
end

describe BotList::Provider do
  it "provides a default name" do
    provider = TestProvider.new
    provider.name.should eq "test_provider"
  end
end

describe BotList::Client do
  it "can be initialized from a Discord::Client" do
    client_with_cache = begin
      client = Discord::Client.new("")
      cache = Discord::Cache.new(client)
      client.cache = cache
    end
    BotList::Client.new(client_with_cache).should be_a BotList::Client

    client_without_cache = Discord::Client.new("")
    expect_raises(Exception, "Client must have a cache set") do
      BotList::Client.new(client_without_cache)
    end
  end

  it "updates each provider" do
    cache = Discord::Cache.new(Discord::Client.new(""))
    client = BotList::Client.new(cache)
    providers = {TestProvider.new, TestProvider.new}
    providers.each { |p| client.add_provider(p) }
    client.update
    providers.each { |p| p.called.should be_true }
  end

  it "adds a stock provider" do
    cache = Discord::Cache.new(Discord::Client.new(""))
    provider = TestProvider.new
    BotList::PROVIDERS["test"] = provider
    client = BotList::Client.new(cache)
    client.add_provider("test")
    client.providers.should eq [provider]

    expect_raises(Exception, %(Unknown provider: "foo". Available providers: "discordbots.org", "discord.bots.gg", "test")) do
      client.add_provider("foo")
    end
  end
end
