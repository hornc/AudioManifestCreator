require_relative '../audio_dir'

describe AudioDir do
  context "directory has no manifest" do
    audio_dir = AudioDir.new("spec/data/no_manifest")
    it "should return false for whether it has a csv audio manifest" do
      audio_dir.should_not have_manifest
    end
    it "should generate and appropriate manifest name based on the directory name" do
      audio_dir.manifest.should == "spec/data/no_manifest_manifest.csv"
    end
  end
  context "directory has a manifest" do
    audio_dir = AudioDir.new("spec/data/has_manifest")
    it "should return true for whether it has a csv audio manifest" do
      audio_dir.should have_manifest
    end
    it "should return the manifest name" do
      audio_dir.manifest.should == "test_manifest.csv"
    end
  end

  it "should list audio file contents (case insensitive) given a set sample_match pattern" do
    audio_dir = AudioDir.new("spec/data", /.mp3$|.wav$/)

    audio_dir.should have_samples

    audio_dir.samples.should be_kind_of(Array)
    audio_dir.should have(5).samples
    audio_dir.samples.each do |s|
      s.should match(/.mp3$|.wav$|.MP3$|.WAV$/)
    end
    
    audio_dir.sample_match = /.doc$/ 
    audio_dir.should_not have_samples

    audio_dir.sample_match = /.mp3$/ 
    audio_dir.should have(2).samples

    audio_dir.sample_match = /.mp4$/ 
    audio_dir.should have(1).samples
  end

  it "should generate a audio manifest csv file given a set sample_match pattern" do
    audio_dir = AudioDir.new("spec/data", /.mp3$|.wav$/)
    result = audio_dir.generate_manifest
    result.should be_kind_of(String)
    result.should match(/Files located at:/)
    result.should match(/Recording, Description, Location,/)
    result.should match(/sample_16bit_01,,,00:03.361,15:44:18,15 Jul 2011,2,16,44100,WAV/)
    result.should match(/sample02,,,00:03.452,15:42:42,15 Jul 2011,2,128kb\/s,44100,MP3/)   # capitalized MP3 extension
  end

  it "should return an array of sample information headers" do
    audio_dir = AudioDir.new("spec/data")
    headers = audio_dir.sample_headers
    headers.should be_kind_of(Array)
    headers.size.should == 10
    headers[0].should == "Recording"
    headers[1].should == "Description"
    headers[9].should == "Format"
  end

  it "should return an array of hashes containing the sample information for each sample" do
    audio_dir = AudioDir.new("spec/data", /.mp3$|.wav$/)
    audio_dir.sample_info.should be_kind_of(Array)
    audio_dir.sample_info[0].should be_kind_of(Hash)
    audio_dir.sample_info[0]["Description"].should == "This is a test description 0001"
    audio_dir.sample_info[0]["Location"].should == "NZ"
    audio_dir.sample_info[1]["Description"].should == "This is a test description 0002"
    audio_dir.sample_info[1]["Location"].should == "South Island, NZ"
  end

  it "should generate and return a .PLS playlist file for all samples it contains" do
    audio_dir = AudioDir.new("spec/data", /.mp3$|.wav$/)
    playlist = audio_dir.generate_playlist
    playlist.should be_kind_of(String)
    playlist.should match("[playlist]")
    playlist.should match("File1=")
    playlist.should match("Title1=")
    playlist.should match("NumberOfEntries=5")
    puts playlist
  end
end
