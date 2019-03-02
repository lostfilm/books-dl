module BooksDL
  module Files
    class Container < ::BooksDL::BaseFile
      def root_file_path
        doc.css('rootfile').first.attr('full-path')
      end

      private

      def doc
        Nokogiri::XML(content)
      end
    end
  end
end