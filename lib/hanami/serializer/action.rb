# frozen_string_literal: true

module Hanami
  module Serializer
    module Action
      def send_json(response, status: 200)
        self.status = status
        self.body = response.respond_to?(:to_json) ? response.to_json : JSON.generate(response)
      end

      def serializer
        @serializer ||=
          begin
            namespaces = self.class.name.split('::')
            namespaces[1] = 'Serializers'
            Hanami::Utils::Class.load(namespaces.join('::'))
          end
      end

      alias :serializator :serializer
    end
  end
end
