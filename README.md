# Logstash Codec - Avro Schema Registry

This plugin is used to serialize Logstash events as
Avro datums, as well as deserializing Avro datums into
Logstash events.

Decode/encode Avro records as Logstash events using the 
associated Avro schema from a Confluent schema registry.
(https://github.com/confluentinc/schema-registry)

##  Decoding (input)

When this codec is used to decode the input, you may pass the following options:
- ``endpoint`` - always required.
- ``username`` - optional.
- ``password`` - optional.

## Encoding (output)

This codec uses the Confluent schema registry to register a schema and
encode the data in Avro using schema_id lookups.

When this codec is used to encode, you may pass the following options:
- ``endpoint`` - always required.
- ``username`` - optional.
- ``password`` - optional.
- ``schema_id`` - when provided, no other options are required.
- ``subject_name`` - required when there is no ``schema_id``.
- ``schema_version`` - when provided, the schema will be looked up in the registry.
- ``schema_uri`` - when provided, JSON schema is loaded from URL or file.
- ``schema_string`` - required when there is no ``schema_id``, ``schema_version`` or ``schema_uri``
- ``check_compatibility`` - will check schema compatibility before encoding.
- ``register_schema`` - will register the JSON schema if it does not exist.
- ``binary_encoded`` - will output the encoded event as a ByteArray.
  Requires the ``ByteArraySerializer`` to be set in the Kafka output config.

## Usage

### Basic usage with Kafka input and output.

```
input {
  kafka {
    ...
    codec => avro_schema_registry {
      endpoint => "http://schemas.example.com"
    }
  }
}
filter {
  ...
}
output {
  kafka {
    ...
    codec => avro_schema_registry {
      endpoint => "http://schemas.example.com"
      subject_name => "my_kafka_subject_name"
      schema_uri => "/app/my_kafka_subject.avsc"
      register_schema => true
    }
  }
}
```

### Binary encoded Kafka output

```
output {
  kafka {
    ...
    codec => avro_schema_registry {
      endpoint => "http://schemas.example.com"
      schema_id => 47
      binary_encoded => true
    }
    value_serializer => "org.apache.kafka.common.serialization.ByteArraySerializer"
  }
}
```