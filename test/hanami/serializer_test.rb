require 'test_helper'

def serialization_output_must_be(expected_json_string)
  it 'emits the expected json string' do
    expect(serializer.to_json).must_equal expected_json_string
    expect(serializer.call).must_equal expected_json_string
    expect(JSON.generate(serializer)).must_equal expected_json_string
    expect(Oj.dump(serializer, mode: :compat, use_to_json: true)).must_equal expected_json_string
  end
end

def serialization_should_validation_error(message_pattern = nil)
  it 'raises a schema validation error' do
    error = assert_raises(Dry::Struct::Error) { serializer.to_json }
    assert_match(message_pattern, error.message) if message_pattern
    error = assert_raises(Dry::Struct::Error) { serializer.call }
    assert_match(message_pattern, error.message) if message_pattern
    error = assert_raises(Dry::Struct::Error) { JSON.generate(serializer) }
    assert_match(message_pattern, error.message) if message_pattern
    error = assert_raises(Dry::Struct::Error) { Oj.dump(serializer, mode: :compat, use_to_json: true) }
    assert_match(message_pattern, error.message) if message_pattern
  end
end

describe Hanami::Serializer do
  let(:serializer) { UserSerializer.new(object) }

  describe '#to_json' do
    describe 'works with empty hash' do
      let(:serializer) { AnonymizableUserSerializer.new(object) }
      let(:object) { {} }

      serialization_output_must_be '{"name":null}'
    end

    describe 'works with hash' do
      describe 'having a required field with a default value' do
        describe 'when the key is missing' do
          let(:object) { { id: 1, email: 'test@site.com', subscribed: true } }

          serialization_output_must_be '{"name":"","email":"test@site.com","subscribed":true}'
        end

        describe 'when the value is missing' do
          let(:object) { { id: 1, name: nil, email: 'test@site.com', subscribed: true } }

          serialization_output_must_be '{"name":"","email":"test@site.com","subscribed":true}'
        end
      end

      describe 'having a required field without a default value' do
        describe 'when the key is missing' do
          let(:object) { { id: 1, name: 'Anton', subscribed: true } }

          serialization_should_validation_error /email is missing/
        end

        describe 'when the value is missing' do
          let(:object) { { id: 1, name: 'Anton', email: nil, subscribed: true } }

          serialization_should_validation_error /email violates constraints/
        end
      end

      describe 'having an optional field with a default value' do
        describe 'when the key is missing' do
          let(:object) { { id: 1, name: 'Anton', email: 'test@site.com' } }

          serialization_output_must_be '{"name":"Anton","email":"test@site.com","subscribed":false}'
        end

        describe 'when the value is missing' do
          let(:object) { { id: 1, name: 'Anton', email: 'test@site.com', subscribed: nil } }

          serialization_output_must_be '{"name":"Anton","email":"test@site.com","subscribed":false}'
        end
      end
    end

    describe 'works with rom-entity' do
      let(:object) { User.new(id: 1, name: 'Anton', email: 'test@site.com', created_at: Time.now) }

      serialization_output_must_be '{"name":"Anton","email":"test@site.com","subscribed":false}'
    end

    describe 'works with nested data' do
      let(:serializer) { UserWithAvatarSerializer.new(object) }

      describe 'for empty nested data' do
        let(:object) { { id: 1, name: 'Anton', email: 'test@site.com', created_at: Time.now } }

        serialization_output_must_be '{"name":"Anton","avatar":{}}'
      end

      describe 'for empty nested data' do
        let(:object) do
          {
            id: 1,
            name: 'Anton',
            email: 'test@site.com',
            created_at: Time.now,
            avatar: {
              upload_file_name: 'test.jpg',
              upload_file_size: 10,
              upload_updated_at: Time.now
            }
          }
        end

        serialization_output_must_be \
          '{"name":"Anton","avatar":{"upload_file_name":"test.jpg","upload_file_size":10}}'
      end
    end

    describe 'works with nested serializer' do
      let(:serializer) { NestedUserSerializer.new(object) }

      describe 'for empty nested data' do
        let(:object) { { id: 1, name: 'Anton', email: 'test@site.com', created_at: Time.now } }

        serialization_output_must_be '{"name":"Anton","avatar":{}}'
      end

      describe 'for empty nested data' do
        let(:object) do
          {
            id: 1,
            name: 'Anton',
            email: 'test@site.com',
            created_at: Time.now,
            avatar: {
              upload_file_name: 'test.jpg',
              upload_file_size: 10,
              upload_updated_at: Time.now
            }
          }
        end

        serialization_output_must_be \
          '{"name":"Anton","avatar":{"upload_file_name":"test.jpg","upload_file_size":10}}'
      end
    end

    describe 'works with #serialized_fields' do
      let(:serializer) { UserWithSelectedFieldsSerializer.new(object) }
      let(:object) do
        {
          id: 1,
          name: 'Anton',
          email: 'test@site.com',
          created_at: Time.now,
          avatar: {
            upload_file_name: 'test.jpg',
            upload_file_size: 10,
            upload_updated_at: Time.now
          }
        }
      end

      serialization_output_must_be '{"name":"Anton"}'
    end
  end
end
