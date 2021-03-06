require 'test_helper'

module Tire

  class ConfigurationTest < Test::Unit::TestCase

    def teardown
      Tire::Configuration.reset
    end

    context "Configuration" do
      setup do
        Configuration.instance_variable_set(:@url,    nil)
        Configuration.instance_variable_set(:@client, nil)
      end

      teardown do
        Configuration.reset
      end

      should "return default URL" do
        assert_equal 'http://localhost:9200', Configuration.url
      end

      should "return default URL when URLS are empty" do
        assert_nothing_raised { Configuration.url [] }
        assert_equal 'http://localhost:9200', Configuration.url
      end

      should "allow setting and retrieving the URL" do
        assert_nothing_raised { Configuration.url 'http://example.com' }
        assert_equal 'http://example.com', Configuration.url
      end

      should "strip trailing slash from the URL" do
        assert_nothing_raised { Configuration.url 'http://slash.com:9200/' }
        assert_equal 'http://slash.com:9200', Configuration.url
      end

      should "allow setting more URLS" do
        assert_nothing_raised { Configuration.url 'http://example1.com', 'http://example2.com' }
        assert_equal ['http://example1.com', 'http://example2.com'], Configuration.urls
      end

      should "strip trailing slash from all the URLS" do
        assert_nothing_raised { Configuration.url ['http://slash1.com:9200/', 'http://slash2.com:9200/'] }
        assert_equal ['http://slash1.com:9200', 'http://slash2.com:9200'], Configuration.urls
      end

      should "retrieve a random URL from the ones available" do
        assert_nothing_raised { Configuration.url 'http://example1.com', 'http://example2.com' }
        url = Configuration.url
        begin
          assert_equal 'http://example1.com', url
        rescue
          assert_equal 'http://example2.com', url
        end
      end

      should "return default client" do
        assert_equal HTTP::Client::RestClient, Configuration.client
      end

      should "return nil as logger by default" do
        assert_nil Configuration.logger
      end

      should "return set and return logger" do
        Configuration.logger STDERR
        assert_not_nil Configuration.logger
        assert_instance_of Tire::Logger, Configuration.logger
      end

      should "allow to reset the configuration for specific property" do
        Configuration.url 'http://example.com'
        assert_equal      'http://example.com', Configuration.url
        Configuration.reset :urls
        assert_equal      'http://localhost:9200', Configuration.url
      end

      should "allow to reset the configuration for all properties" do
        Configuration.url     'http://example.com'
        Configuration.wrapper Hash
        assert_equal          'http://example.com', Configuration.url
        Configuration.reset
        assert_equal          'http://localhost:9200', Configuration.url
        assert_equal          HTTP::Client::RestClient, Configuration.client
      end
    end

  end

end
