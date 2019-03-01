module BooksDL
  class Utils
    def self.hex_string_to_byte(hex)
      return [] unless hex.is_a?(String)

      hex.scan(/../).map(&:hex)
    end

    def self.xor_decoder
      # TODO
    end

    def self.decode_data
      # TODO
    end

    def self.get_real
      # TODO
    end
    def self.pad_left
      # TODO
    end

    def self.img_decode
      # TODO
    end
  end
end
