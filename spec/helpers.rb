module Helpers
  RSPEC_ROOT_PATH = "#{__FILE__.split('/spec/').first}/spec".freeze

  def file_fixture(file_name)
    file_path = File.join(RSPEC_ROOT_PATH, 'fixtures', 'files', file_name)

    File.open(file_path)
  end
end
