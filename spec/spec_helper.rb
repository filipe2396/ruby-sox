require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sox'
require 'rspec'
require 'chromaprint'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}


FIXTURES_PATH = File.expand_path('../integration/fixtures', __FILE__)

RSpec.configure do |config|
  # Build path to input fixture.
  #
  # @param file [String] filename
  #
  # @return [String] full path to fixture in +input+ dir
  def input_fixture(file)
    File.join(FIXTURES_PATH, 'input', file)
  end

  # Build path to output fixture.
  #
  # @param file [String] filename
  #
  # @return [String] full path to fixture in +output+ dir
  def output_fixture(file)
    File.join(FIXTURES_PATH, 'output', file)
  end

  # Generate filename for temporary file.
  #
  # @param ext [String] file extension
  #
  # @return [String] filename
  def gen_tmp_filename(ext = 'mp3')
    time = Time.now.strftime('%Y%m%d')
    name = "ruby-sox-test#{time}-#{Process.pid}-#{rand(0x100000000).to_s(36)}.#{ext}"

    ::File.join(Dir.tmpdir, name)
  end
end
