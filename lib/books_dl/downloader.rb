require 'zip'

module BooksDL
  class Downloader
    attr_reader :api, :book, :book_id, :info

    def initialize(book_id)
      @book_id = book_id
      @api = API.new(book_id)
      @book = {
        root_file_path: nil,
        root_file: nil,
        files: [
          ::BooksDL::BaseFile.new('mimetype', 'application/epub+zip')
        ]
      }

    end

    def perform
      job('取得 META-INF/container.xml') { fetch_container_file }
      job('取得 META-INF/encryption.xml') { fetch_encryption_file }
      job("取得 #{book[:root_file_path]} 檔案") { fetch_root_file }
      fetch_book_content # 由內部顯示 job 訊息
      job('製作 epub 檔案') { build_epub }

      puts "#{book_id} 下載完成"
    end

    private

    def job(name)
      print "正在#{name}..."
      puts '成功' if yield
    end

    def fetch_container_file
      path = 'META-INF/container.xml'
      content = api.fetch(path)
      container_file = Files::Container.new(path, content)

      book[:root_file_path] = container_file.root_file_path
      book[:files] << container_file
    end

    def fetch_encryption_file
      path = 'META-INF/encryption.xml'
      content = api.fetch(path)
      encryption_file = BaseFile.new(path, content)

      book[:files] << encryption_file
    rescue StandardError => e
      puts "\n#{e}"
      puts "Just a encryption file, it doesn't matter..."

      false
    end

    def fetch_root_file
      path = book[:root_file_path]
      content = api.fetch(path)
      root_file = Files::Content.new(path, content)

      book[:root_file] = root_file
      book[:files] << root_file
    end

    def fetch_book_content
      root_file = book[:root_file]
      file_paths = root_file.file_paths

      total = file_paths.size
      file_paths.each_with_index do |path, index|
        puts "#{index + 1}/#{total} => 開始下載 #{path}"
        content = api.fetch(path)

        book[:files] << BaseFile.new(path, content)
      end
    end

    def build_epub
      title = book[:root_file].title
      files = book[:files]
      filename = "#{book_id}_#{title}.epub"

      ::Zip::File.open(filename, ::Zip::File::CREATE) do |zipfile|
        files.each do |file|
          zipfile.get_output_stream(file.path) { |zip| zip.write(file.content) }
        end
      end
    end
  end
end