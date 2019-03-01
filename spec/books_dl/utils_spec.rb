describe BooksDL::Utils do
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

  describe '.get_real' do
    let(:url) { 'https://streaming-ebook.books.com.tw/V1.0/Streaming/book/DD0CB3/952170/OEBPS/content.opf' }
    let(:decode) { [101, 87, 67, 247, 38, 70, 65, 140, 139, 83, 14, 193, 211, 197, 38, 225, 48, 35, 79, 108, 47, 47, 191, 253, 44, 205, 93, 130, 226, 96, 203, 82] }

    it 'return decode bytes array' do
      return_value = described_class.get_real(url)

      expect(return_value).to be_a Array
      expect(return_value).to eq decode
    end
  end
end
