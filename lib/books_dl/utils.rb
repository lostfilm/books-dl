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
      hex_string_to_byte(decode_hex)
    end

    def xor_decoder(url, encrypted_content)
      decode = get_real(url)
      count = 0
      tmp = []
      bytes = encrypted_content.bytes

      (0...bytes.size).each do |idx|
        tmp[idx] = bytes[idx] ^ decode[count]
        count += 1
        count = 0 if count >= decode.size
      end

      tmp = tmp[3..] if (tmp[0] == 239) && (tmp[1] == 187) && (tmp[2] == 191)

      result = if tmp.size > 10_000
                 count2 = (tmp.size / 10_000.0).ceil
                 (0...count2).each do |idx|
                   tmp[idx] = tmp[idx * 10_000...(idx + 1) * 10_000]
                 end

                 tmp[0..count2]
               else
                 tmp
               end.pack('c*')

      result.force_encoding('utf-8')
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

    private

    def hex_string_to_byte(hex)
      self.class.hex_string_to_byte(hex)
    end
  end
end
