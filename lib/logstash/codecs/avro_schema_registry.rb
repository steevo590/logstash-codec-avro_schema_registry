# encoding: utf-8
require "avro"
require "schema_registry"
require "schema_registry/client"
require "logstash/codecs/base"
require "logstash/namespace"
require "logstash/event"
require "logstash/timestamp"
require "logstash/util"

MAGIC_BYTE = 0

# Read serialized Avro records as Logstash events
#
# This plugin is used to serialize Logstash events as
# Avro datums, as well as deserializing Avro datums into
# Logstash events.
#
# ==== Encoding
#
# This codec currently does not encode. This might be added later.
#
#
# ==== Decoding
#
# This codec is for deserializing individual Avro records. It looks up
# the associated avro schema from a Confluent schema registry.
# (https://github.com/confluentinc/schema-registry)
#
#
# ==== Usage
# Example usage with Kafka input.
#
# [source,ruby]
# ----------------------------------
# input {
#   kafka {
#     codec => avro_schema_registry {
#       endpoint => "http://schemas.example.com"
#     }
#   }
# }
# filter {
#   ...
# }
# output {
#   ...
# }
# ----------------------------------
class LogStash::Codecs::AvroSchemaRegistry < LogStash::Codecs::Base
  config_name "avro_schema_registry"

  # schema registry endpoint and credentials
  config :endpoint, :validate => :string, :required => true
  config :username, :validate => :string, :default => nil
  config :password, :validate => :string, :default => nil
  config :schema_id, :validate => :number, :default => nil

  public
  def register
    @client = SchemaRegistry::Client.new(endpoint, username, password)
    @schemas = Hash.new
  end

  def get_schema(schema_id)
    if !@schemas.has_key?(schema_id)
      @schemas[schema_id] = Avro::Schema.parse(@client.schema(schema_id))
    end
    @schemas[schema_id]
  end

  public
  def decode(data)
    if data.length < 5
      @logger.error('message is too small to decode')
    else
      datum = StringIO.new(data)
      magic_byte, schema_id = datum.read(5).unpack("cI>")
      if magic_byte != MAGIC_BYTE
        @logger.error('message does not start with magic byte')
      else
        schema = get_schema(schema_id)
        decoder = Avro::IO::BinaryDecoder.new(datum)
        datum_reader = Avro::IO::DatumReader.new(schema)
        yield LogStash::Event.new(datum_reader.read(decoder))
      end
    end
  end

  public
  def encode(event)
    schema = get_schema(@schema_id)
    dw = Avro::IO::DatumWriter.new(schema)
    buffer = StringIO.new
    buffer.write(MAGIC_BYTE.chr)
    buffer.write([schema_id].pack("I>"))
    encoder = Avro::IO::BinaryEncoder.new(buffer)
    dw.write(event.to_hash, encoder)
    @on_event.call(event, buffer.string.to_java_bytes)
  end
end
