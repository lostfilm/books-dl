module BooksDL
  class Utils
    def self.hex_to_byte(hex)
      return [] unless hex.is_a?(String)

      hex.scan(/../).map(&:hex)
    end

    def self.generate_key(url, download_token)
      puts url
      file_path = CGI.unescape(url.match(%r|https://(.*?/){3}.*?(?<rest_part>/.+)|)[:rest_part])
      md5_chars = Digest::MD5.hexdigest(file_path).split('')
      partition = md5_chars.each_slice(4).reduce(0) do |num, chars|
        (num + Integer("0x#{chars.join}")) % 64
      end
      decode_hex = Digest::SHA256.hexdigest("#{download_token[0...partition]}#{file_path}#{download_token[partition..]}")

      hex_to_byte(decode_hex)
    end

    def self.decode_xor(key, encrypted_content)
      count = 0
      tmp = []
      bytes = encrypted_content.bytes

      (0...bytes.size).each do |idx|
        tmp[idx] = bytes[idx] ^ key[count]
        count += 1
        count = 0 if count >= key.size
      end

      tmp = tmp[3..] if (tmp[0] == 239) && (tmp[1] == 187) && (tmp[2] == 191)

      result = if tmp.size > 10_000
                 count2 = (tmp.size / 10_000.0).ceil
                 (0...count2).each do |idx|
                   tmp[idx] = tmp[idx * 10_000...(idx + 1) * 10_000]
                 end

                 tmp[0...count2].reduce('') { |str, bytes| str << bytes.pack('c*') }
               else
                 tmp.pack('c*')
               end

      result.force_encoding('utf-8')
    end

    def self.img_checksum
      seed = %w[0 6 9 3 1 4 7 1 8 0 5 5 9 A A C]
      (0...seed.size).each do |idx|
        rand_idx = (0...seed.size).to_a.sample
        seed[idx], seed[rand_idx] = seed[rand_idx], seed[idx]
      end
      seed.join
    end
  end
end
