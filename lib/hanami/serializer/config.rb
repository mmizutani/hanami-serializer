require 'json'

module Hanami
  module Serializer
    class Config
      attr_accessor :json_engine

      def initialize
        # JSON Engine for Ruby object marshalling
        # Available options:
        #   nil  JSON in Ruby's standard library
        #   :oj  Oj (a high performance alternative gem written in C)
        @json_engine = nil
      end
    end

    module Configurable
      class << self
        attr_accessor :config
      end

      def config
        @config ||= Config.new
      end

      def configure
        yield config
      end
    end
  end
end
