module BooksDL
  class Utils
    attr_accessor :download_token

    def initialize(download_token:)
      @download_token = download_token.strip
    end

    def self.hex_string_to_byte(hex)
      return [] unless hex.is_a?(String)

      hex.scan(/../).map(&:hex)
    end

    def get_real(url)
      file_path = CGI.unescape(url.match(%r{https://(.*?/){3}.*?(?<rest_part>/.+)})[:rest_part])
      md5_chars = Digest::MD5.hexdigest(file_path).split('')
      partition = md5_chars.each_slice(4).reduce(0) do |num, chars|
        (num + Integer("0x#{chars.join}")) % 64
      end
      decode_hex = Digest::SHA256.hexdigest("#{download_token[0...partition]}#{file_path}#{download_token[partition..]}")
      self.class.hex_string_to_byte(decode_hex)
    end

    def self.xor_decoder
      # TODO
    end

    def self.decode_data
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
