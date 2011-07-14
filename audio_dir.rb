require_relative 'sample_info'
require 'erb'
require 'ostruct'

class AudioDir < Dir
  attr_accessor :sample_match, :manifest

  def initialize(name, sample_match=/.*mp3|.*wav/)
    super(name)
    @sample_match = sample_match
  end

  def has_manifest?
    manifest_found = false
    self.each do |f|
      if f.end_with?(".csv")
        manifest_found = true 
        @manifest = f
      end
    end
    manifest_found
  end

  def manifest
    if self.has_manifest?
      @manifest
    else
      "#{self.path}_manifest.csv"
    end
  end

  def samples
    output = []
    self.each do |s|
      output << s if s.match(sample_match)
    end
    output
  end
  
  def has_samples?
    self.samples.length != 0
  end

  def sample_headers
    ["Recording", "Description", "Location", "Duration", "Time", "Date", "Channels", "Bits", "Sample Rate", "Format"]
  end

  def sample_info
    samples = []
    self.samples.each do |s|
      s = "#{self.path}/#{s}"
      samples << WavInfo.new(s).info if s.upcase.include?(".WAV")
      samples << Mp3Info.new(s).info if s.upcase.include?(".MP3")
    end
    samples  
  end

  def generate_manifest
    manifest_template = ERB.new File.new("#{Dir.getwd}/audio_manifest.csv.erb").read, nil, "-"
    samples = []
    self.samples.each do |s|
      s = "#{self.path}/#{s}"
      samples << WavInfo.new(s) if s.upcase.include?(".WAV")
      samples << Mp3Info.new(s) if s.upcase.include?(".MP3")
    end
    location = self
    vars = OpenStruct.new :location => location, :samples => samples
    doc = manifest_template.result(vars.send(:binding))
  end

end
