describe BooksDL::Utils do
  let (:download_token) { file_fixture('download_token.txt').read }
  subject { BooksDL::Utils.new(download_token: download_token) }

  describe '.hexStringToByte' do
    let(:hex) { 'ABCDEFG987654321' }
    let(:bytes_array) { [171, 205, 239, 0, 135, 101, 67, 33] }

    it 'return empty array when input is nil' do
      return_value = described_class.hex_string_to_byte(nil)

      expect(return_value).to be_a Array
      expect(return_value).to be_empty
    end

    it 'return byte array correctly' do
      return_value = described_class.hex_string_to_byte(hex)

      expect(return_value).to be_a Array
      expect(return_value).to eq bytes_array
    end
  end

  describe '.pad_left' do
    it 'return original string when string#size > 7' do
      expect(described_class.pad_left('12345678')).to eq '12345678'
      expect(described_class.pad_left('999999999')).to eq '999999999'
    end

    it 'return padded string when string#size <= 7' do
      expect(described_class.pad_left('123')).to eq '00000123'
      expect(described_class.pad_left('1234')).to eq '00001234'
      expect(described_class.pad_left('1')).to eq '00000001'
    end
  end

  describe '#get_real' do
    let(:url) { 'https://streaming-ebook.books.com.tw/V1.0/Streaming/book/DD0CB3/952170/OEBPS/content.opf' }
    let(:url2) { 'https://streaming-ebook.books.com.tw/V1.0/Streaming/book/DD0CB3/952170/META-INF/container.xml' }
    let(:decode) { [101, 87, 67, 247, 38, 70, 65, 140, 139, 83, 14, 193, 211, 197, 38, 225, 48, 35, 79, 108, 47, 47, 191, 253, 44, 205, 93, 130, 226, 96, 203, 82] }
    let(:decode2) { [125, 142, 71, 182, 184, 151, 206, 229, 41, 53, 224, 96, 131, 141, 200, 22, 28, 118, 85, 249, 243, 74, 28, 193, 218, 219, 4, 243, 201, 221, 108, 117] }

    it 'return decode bytes array' do
      return_value = subject.get_real(url)

      expect(return_value).to be_a Array
      expect(return_value).to eq decode
    end

    it 'return decode2 bytes array' do
      return_value = subject.get_real(url2)

      expect(return_value).to be_a Array
      expect(return_value).to eq decode2
    end
  end

  describe '#xor_decoder' do
    let(:url) { 'https://streaming-ebook.books.com.tw/V1.0/Streaming/book/DD0CB3/952170/OEBPS/content.opf' }
    let(:encrypted_content_opf) { file_fixture('encrypted_content.opf').read }
    let(:content_opf) { file_fixture('content.opf').read }

    let(:url2) { 'https://streaming-ebook.books.com.tw/V1.0/Streaming/book/DD0CB3/952170/META-INF/container.xml' }
    let(:encrypted_container_xml) { file_fixture('encrypted_container.xml').read }
    let(:container_xml) { file_fixture('container.xml').read }

    it 'return decoded content opf' do
      return_value = subject.xor_decoder(url, encrypted_content_opf)

      expect(return_value).to eq content_opf
    end

    it 'return decoded container.xml' do
      return_value = subject.xor_decoder(url2, encrypted_container_xml)

      expect(return_value).to eq container_xml
    end
  end
end
