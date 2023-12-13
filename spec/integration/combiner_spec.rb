require 'spec_helper'
require 'benchmark'

shared_examples_for "combiner" do |options|
  strategy = options[:strategy]

  # Input fixtures
  let(:drums_input)   { input_fixture('drums_128kb.mp3')          }
  let(:guitar1_input) { input_fixture('guitar1_192kb_stereo.mp3') }
  let(:guitar2_input) { input_fixture('guitar2.wav')              }
  let(:guitar3_input) { input_fixture('guitar3.wav')              }

  let(:output_file) { gen_tmp_filename('mp3') }

  after do
    FileUtils.rm output_file if File.exist?(output_file)
  end


  describe "strategy=#{strategy}" do
    describe 'concatenation' do
      let(:output_file) { gen_tmp_filename('flac') }

      it 'should mix should write output with 2 channels' do
        files = [drums_input, guitar1_input, guitar2_input, guitar3_input]
        combiner = Sox::Combiner.new(files,
                                     :combine  => :mix,
                                     :channels => 2 ,
                                     :rate     => 44100,
                                     :strategy => strategy)
        combiner.write(output_file)

        File.exist?(output_file).should be_true
        output_file.should have_rate(44100)
        output_file.should have_channels(2)
        output_file.should sound_like output_fixture("d_g1_g2_g3_mixed_c2_r44100.flac")
      end

      it 'should concatenate' do
        files = [drums_input, guitar2_input, guitar3_input]
        combiner = Sox::Combiner.new( files,
                                      :combine  => :concatenate,
                                      :strategy => strategy )
        combiner.write(output_file)

        File.exist?(output_file).should be_true
        # Test default options
        output_file.should have_rate(22050)
        output_file.should have_channels(1)
        output_file.should sound_like output_fixture("d_g2_g3_concatenated_c1_r22050.flac")
      end
    end


    describe 'mixing' do
      let(:output_file) { gen_tmp_filename('mp3') }

      it 'should mix' do
        files = [drums_input, guitar2_input, guitar3_input]
        combiner = Sox::Combiner.new( files,
                                      :combine  => :mix,
                                      :strategy => strategy )
        combiner.write(output_file)

        File.exist?(output_file).should be_true
        output_file.should sound_like output_fixture("d_g2_g3_mixed_c1_r22050.mp3")
      end

      context 'with normalization' do
        it 'should mix and normalize' do
          files = [drums_input, guitar2_input, guitar3_input]
          combiner = Sox::Combiner.new( files,
                                        :combine  => :mix,
                                        :norm     => true,
                                        :strategy => strategy )
          combiner.write(output_file)

          File.exist?(output_file).should be_true
          output_file.should sound_like output_fixture("d_g2_g3_mixed_c1_r22050_norm.mp3")
        end
      end
    end


    context '1 input file' do
      it 'should' do
        combiner = Sox::Combiner.new( [drums_input],
                                      :combine  => :concatenate,
                                      :strategy => strategy )
        combiner.write(output_file)

        File.exist?(output_file).should be_true
        output_file.should sound_like output_fixture("drums.mp3")
      end
    end


    context 'errors' do
      it 'should raise Sox::Error when input file does not exist' do
        combiner = Sox::Combiner.new( ['/silence.mp3', '/noise.mp3'],
                                      :strategy => strategy )
        expect { combiner.write(output_file) }.
          to raise_error(Sox::Error, %r{can't open input file `/silence.mp3'})
      end

      it 'input files are missing' do
        expect { Sox::Combiner.new([], :strategy => strategy) }.
          to raise_error(ArgumentError, "Input files are missing")
      end
    end

    if options[:benchmark]
      describe 'benchmarks' do
        let(:big_input_files) { [] }

        let(:rates) { [8000, 16000, 22050, 32000, 44100, 48000] }
        let(:input_files) { [drums_input, guitar1_input, guitar2_input, guitar3_input] }

        # We expect all 4 files to have same duration =~ 8 sec
        let(:small_duration) { (%x"soxi -D #{drums_input}").to_i }

        after do
          big_input_files.each do |file|
            FileUtils.rm file if File.exist?(file)
          end
        end

        it 'should concatenate' do
          small_input_files = input_files * 6

          # Run benchmark against 24 files 8 seconds each
          Benchmark.bm(20) do |x|
            rates.each do |rate|
              duration     = small_duration
              count        = small_input_files.size
              sum_duration = duration * count

              x.report("#{duration}s*#{count}=#{sum_duration}s rate=#{rate}" ) do
                Sox::Combiner.new(small_input_files,
                                  :combine  => :concatenate,
                                  :rate     => rate,
                                  :strategy => strategy).
                              write(output_file)
              end
            end
          end

          # Generate big input files 8s*4 = 32s
          rates.each do |rate|
            file = gen_tmp_filename('mp3')
            Sox::Combiner.new(input_files,
                              :combine  => :concatenate,
                              :rate     => rate,
                              :strategy => strategy).
                          write(file)
            big_input_files << file
          end

          # Run benchmark against 6 files 32 seconds each
          Benchmark.bm(20) do |x|
            duration     = small_duration * input_files.size
            count        = big_input_files.size
            sum_duration = duration * count

            rates.each do |rate|
              x.report("#{duration}s*#{count}=#{sum_duration}s rate=#{rate}" ) do
                Sox::Combiner.new(big_input_files,
                                  :combine  => :concatenate,
                                  :rate     => rate,
                                  :strategy => strategy).
                              write(output_file)
              end
            end
          end
        end
      end
    end
  end
end


# Uncomment `:benchmark => true` if you want to see benchmark comparison of
# different strategies.
# Usually :process_substitution is 1.5-2 faster than :tmp_file, because it
# doesn't use disk IO to save temporary files.
describe "Sox::Combiner" do
  it_behaves_like "combiner", :strategy => :tmp_file              # , :benchmark => true
  it_behaves_like "combiner", :strategy => :process_substitution  # , :benchmark => true
end
