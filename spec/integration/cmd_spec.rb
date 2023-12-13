require 'spec_helper'

describe "Sox::Cmd integration" do

  let(:output_file) { gen_tmp_filename('mp3') }

  after do
    FileUtils.rm output_file if File.exist?(output_file)
  end


  it 'should mix 2 input files and convert to output with rate=44100 and 2 channels' do
    # Files with same rate and number of channels
    in1 = input_fixture('guitar2.wav')
    in2 = input_fixture('guitar3.wav')

    Sox::Cmd.new(:combine => :mix)
      .add_input(in1, :type => :wav)
      .add_input(in2, :type => :wav)
      .set_output(output_file)
      .set_effects(:rate => 44100, :channels => 2)
      .run

    File.exist?(output_file).should be_true
    output_file.should have_rate(44100)
    output_file.should have_channels(2)
    output_file.should sound_like output_fixture("g2_g3_mixed_r44100_c2.mp3")
  end

  it 'should apply chorus effect on drums' do
    input = input_fixture('drums_128kb.mp3')

    Sox::Cmd.new
      .add_input(input)
      .set_output(output_file)
      .set_effects(:chorus => '0.99 0.9 55 0.4 0.25 2 -s')
      .run

    File.exist?(output_file).should be_true
    output_file.should sound_like output_fixture("drums_chorus.mp3")
  end
end
