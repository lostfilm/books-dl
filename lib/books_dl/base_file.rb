module BooksDL
  class BaseFile
    attr_reader :path, :content

    def initialize(path, content)
      @path = path
      @content = content
    end
  end
end