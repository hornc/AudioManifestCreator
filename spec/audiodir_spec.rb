require_relative '../audio_dir'

describe AudioDir do
  let(:test_dir)         { AudioDir.new("spec/data", /.mp3$|.wav$/) }
  let(:without_manifest) { AudioDir.new("spec/data/no_manifest") }
  let(:with_manifest)    { AudioDir.new("spec/data/has_manifest") }
  let(:date_time)        { /\d{2}:\d{2}:\d{2},\d{1,2} \w{3} \d{4}/ }

  context "directory has no manifest" do
    subject { without_manifest }
    it { should_not have_manifest }
    it "should generate and appropriate manifest name based on the directory name" do
      expect(subject.manifest).to eq "spec/data/no_manifest_manifest.csv"
    end
  end

  context "directory has a manifest" do
    subject { with_manifest }
    it { should have_manifest }
    it "should return the manifest name" do
      expect(subject.manifest).to eq "test_manifest.csv"
    end
  end

  describe "directory samples" do
    # should be a list of audio file contents (case insensitive) matching sample_match
    subject { test_dir }
    it { should have_samples }
    it "should have the correct number of samples" do
      expect(subject.samples.size).to eq 5
    end
    it "should have samples of the correct type" do
      subject.samples.each do |s|
        expect(s).to match /.mp3$|.wav$|.MP3$|.WAV$/
      end
    end
    it "should be empty when pattern does not match" do
      subject.sample_match = /.doc$/
      is_expected.to_not have_samples
    end
    it "should list case mixed extensions" do
      subject.sample_match = /.mp3$/
      expect(subject.samples.size).to eq 2
    end
    it "should include .mp4" do
      subject.sample_match = /.mp4$/
      expect(subject.samples.size).to eq 1
    end
  end

  describe "generated audio manifest csv" do
    subject { test_dir.generate_manifest }
    it { should be_kind_of(String) }
    it { should match(/Files located at:/) }
    it { should match(/Recording, Description, Location,/) }
    it { should match(/sample_16bit_01,,,00:03.361,#{date_time},2,16,44100,WAV/) }
    it { should match(/sample02,,,00:03.452,#{date_time},2,128kb\/s,44100,MP3/) } # capitalized MP3 extension
  end

  describe "header columns of the samples" do
    subject { test_dir.sample_headers }
    it "should have the correct number of headers" do
      expect(subject.size).to eq 10
    end
    it "has expected titles and order" do
      expect(subject[0]).to eq 'Recording'
      expect(subject[1]).to eq 'Description'
      expect(subject[9]).to eq 'Format'
    end
  end

  describe "sample information" do
    subject { test_dir.sample_info }
    it "should be an array of hashes" do
      expect(subject[0]).to be_kind_of Hash
    end
    it "should expected location and description" do
      expect(subject[0]["Description"]).to eq "This is a test description 0001"
      expect(subject[0]["Location"]).to eq "NZ"
      expect(subject[1]["Description"]).to eq "This is a test description 0002"
      expect(subject[1]["Location"]).to eq "South Island, NZ"
    end
  end

  describe "generated .PLS playlist" do
    subject { test_dir.generate_playlist }
    it { should be_kind_of String }
    it { should match("[playlist]") }
    it { should match("File1=") }
    it { should match("Title1=") }
    it { should match("NumberOfEntries=5") }
  end
end
