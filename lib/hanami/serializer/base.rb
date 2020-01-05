require 'dry-struct'

module Hanami
  module Serializer
    class Base < Dry::Struct
      transform_types do |schema_key|
        # Type-safely handle nil values of a field with no default value defined.
        schema_key.constructor { |value| value.nil? ? Dry::Types::Undefined : value }
      end

      class << self
        def serialized_fields(attributes)
          @serialized_fields = attributes
        end

        def current_serialized_fields
          @serialized_fields
        end
      end

      def initialize(attributes)
        attributes = Hash(attributes)
        super
      end

      def to_json(_ = nil)
        if Hanami::Serializer.config.json_engine == :oj && defined?(Oj)
          Oj.dump(attributes_for_serialize(to_h), mode: :compat, use_to_json: true)
        else
          JSON.generate(attributes_for_serialize(to_h))
        end
      end
      alias_method :call, :to_json

      def serialized_fields
        self.class.current_serialized_fields
      end

      private

      def attributes_for_serialize(attributes)
        return attributes unless serialized_fields
        attributes.select do |key, _|
          serialized_fields.include?(key)
        end
      end
    end
  end
end
