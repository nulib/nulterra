bundle_path = Dir.glob(File.expand_path('../vendor/bundle/ruby/*', __FILE__)).first
Gem.paths = { 'GEM_PATH' => bundle_path }
require 'noid'
require 'redis'
require 'redlock'

def handler(event: {}, context: {})
  config = { redis_url: ENV['REDIS_URL'], noid_template: ENV['NOID_TEMPLATE'], state_key: ENV['STATE_KEY'] }
  Noid::Lambda.new(config).mint
end

module Noid
  class Lambda
    attr :config

    DEFAULTS = { redis_url: 'redis://localhost:6379/', noid_template: '.reeddeeddk', state_key: 'noid:state' }

    def initialize(config = {})
      @config = DEFAULTS.merge(config.compact)
    end

    def mint
      result = nil
      lock_manager.lock!("#{config[:state_key]}:lock", 2000) do
        load_state!
        { result: minter.mint }
      ensure
        save_state!
      end
    end

    def load_state!
      redis.exists(config[:state_key]) ? Marshal.load(redis.get(config[:state_key])) : { template: config[:noid_template] }
    end

    def save_state!
      redis.set(config[:state_key], Marshal.dump(minter.dump))
    end

    def lock_manager
      @lock_manager ||= Redlock::Client.new([config[:redis_url]])
    end

    def minter
      @minter ||= Noid::Minter.new(load_state!)
    end

    def redis
      @redis ||= Redis.new(url: config[:redis_url])
    end
  end
end