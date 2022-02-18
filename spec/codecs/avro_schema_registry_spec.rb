# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require 'avro'
require 'logstash/codecs/avro_schema_registry'
require 'logstash/event'
require 'avro_turf/messaging'
require 'avro_turf/test/fake_confluent_schema_registry_server'
require 'webmock/rspec'

describe LogStash::Codecs::AvroSchemaRegistry do
  let(:avro_config) {{ 'endpoint' => registry_url }}
  let(:avro) { AvroTurf::Messaging.new(registry_url: registry_url, schemas_path: 'spec/support/avro_schemas') }
  let(:registry_url) { 'http://registry.example.com' }

  before :each do
    stub_request(:any, /^#{registry_url}/).to_rack(FakeConfluentSchemaRegistryServer)
    FakeConfluentSchemaRegistryServer.clear
  end

  subject do
    LogStash::Codecs::AvroSchemaRegistry.new(avro_config)
  end

  context "#decode" do
    it "decodes salsify_uuid as a string" do
      data = avro.encode({ id: 's-00112233-4455-6677-8899-aabbccddeeff' }, schema_name: 'com.salsify.record_with_salsify_uuid')

      subject.decode(data) do |event|
        expect(event.get('id')).to eq('s-00112233-4455-6677-8899-aabbccddeeff')
      end
    end

    it "decodes salsify_uuid_binary as a string" do
      binary_id = "\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xaa\xbb\xcc\xdd\xee\xff"
      data = avro.encode({ id: binary_id }, schema_name: 'com.salsify.record_with_salsify_uuid_binary')

      subject.decode(data) do |event|
        expect(event.get('id')).to eq('s-00112233-4455-6677-8899-aabbccddeeff')
      end
    end
  end

  context "#encode" do
    context "salsify_uuid_binary" do
      let(:avro_config) do
        super().merge(
          'subject_name' => 'com.salsify.record_with_salsify_uuid',
          'schema_uri' => 'spec/support/avro_schemas/com/salsify/record_with_salsify_uuid_binary.avsc',
          'register_schema' => true
        )
      end

      it "encodes the text representation" do
        got_event = false

        event = LogStash::Event.new(id: 's-00112233-4455-6677-8899-aabbccddeeff')

        subject.on_event do |_, data|
          record = avro.decode(data.to_s)
          expect(record['id']).to eq('s-00112233-4455-6677-8899-aabbccddeeff')
          got_event = true
        end

        subject.encode(event)
        expect(got_event).to eq(true)
      end

      it "encodes the binary representation" do
        got_event = false

        event = LogStash::Event.new(id: "\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xaa\xbb\xcc\xdd\xee\xff")

        subject.on_event do |_, data|
          record = avro.decode(data.to_s)
          expect(record['id']).to eq('s-00112233-4455-6677-8899-aabbccddeeff')
          got_event = true
        end

        subject.encode(event)
        expect(got_event).to eq(true)
      end
    end
  end
end
