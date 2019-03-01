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
      expect(return_value).to eq(bytes_array)
    end
  end
end
