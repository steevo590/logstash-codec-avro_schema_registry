# The salsify_uuid avro type stores UUIDs as 38 byte strings in their canonical
# text form.

# The salsify_uuid_binary schema stores UUIDs as 16 bytes to save on
# space. However, we want to convert those values to their text form when
# storing in Elasticsearch.

# Avro supports logical types which perform type conversions on
# read. Unfortunately we don't have a logical type on the salsify_uuid_binary,
# however we can tie into the type adapter with our own custom logic.

# The salsify_uuid_binary is defined as a "fixed" type in Avro, so we're
# injecting this patch just for those types.

# The encoding part will accept either the binary or text representation when
# writing. When reading it should always be in the 16 byte format.

module SalsifyUuidBinaryCodec
  def self.encode(datum)
    if datum.bytesize == 38
      datum[2..-1].split('-').pack('H8 H4 H4 H4 H12')
    else
      datum
    end
  end

  def self.decode(datum)
    datum.unpack('H8 H4 H4 H4 H12').join('-').prepend('s-')
  end
end

module DecodeSalsifyUuidBinaryPatch
  def type_adapter
    if fullname == 'com.salsify.salsify_uuid_binary'
      SalsifyUuidBinaryCodec
    else
      super
    end
  end
end

Avro::Schema::FixedSchema.prepend(DecodeSalsifyUuidBinaryPatch)
