require_relative '../sample_info'

describe SampleInfo do

  describe "WavInfo" do
    subject { SampleInfo.create("spec/data/sample_16bit_01.wav") }
    it { should be_kind_of WavInfo }
  end

  describe "Mp3Info" do
    subject { SampleInfo.create("spec/data/sample_01.mp3") }
    it { should be_kind_of Mp3Info }
  end

  describe "SampleInfo (uknown foramt)" do
    subject { SampleInfo.create("spec/data/test_invalid_mp4.mp4") }
    it { should be_kind_of SampleInfo }
  end

  describe ".seconds_to_duration" do
    subject { SampleInfo.create("spec/data/sample_16bit_01.wav") }
    it "should convert seconds into a correctly formatted readable string (H:)MM:SS.000" do
      expect(subject.seconds_to_duration(100)).to eq "01:40"
      expect(subject.seconds_to_duration(100.1234)).to eq "01:40.123"
      expect(subject.seconds_to_duration(3650)).to eq "1:00:50"
      expect(subject.seconds_to_duration(3650.1234567)).to eq "1:00:50.123"
    end
  end

end
