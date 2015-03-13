require_relative '../sample_info'

describe SampleInfo do
  context "When a new SampleInfo object is created" do
    it "should return a WavInfo object if the sample file is a wav" do
      s=SampleInfo.create("spec/data/sample_16bit_01.wav")
      s.should be_kind_of(WavInfo)
    end

    it "should return a Mp3Info object if the sample file is a mp3" do
      s=SampleInfo.create("spec/data/sample_01.mp3")
      s.should be_kind_of(Mp3Info)
    end

    it "should return a SampleInfo object if the sample file is an unknown file format" do
      s=SampleInfo.create("spec/data/test_invalid_mp4.mp4")
      s.should be_kind_of(SampleInfo)
    end
  end

  it "should convert seconds into a correctly formatted readable string (H:)MM:SS.000" do
    s=SampleInfo.create("spec/data/sample_16bit_01.wav")
    s.seconds_to_duration(100).should == "01:40"
    s.seconds_to_duration(100.1234).should == "01:40.123"
#    s.seconds_to_duration(100.1239).should == "01:40.124"
    s.seconds_to_duration(3650).should == "1:00:50"
    s.seconds_to_duration(3650.1234567).should == "1:00:50.123"
  end

end
