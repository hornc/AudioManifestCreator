require_relative 'sample_info'
require 'erb'
require 'ostruct'

class AudioDir < Dir
  attr_accessor :sample_match, :manifest

  def initialize(name, sample_match=/.mp3$|.wav$/)
    super(name)
    has_manifest?
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
      if self.path == "." then name = "main" else name = self.path end
      "#{name}_manifest.csv"
    end
  end

  def samples
    output = []
    self.sort.each do |s|
      # s = "#{self.path}/#{s}"
      output << s if s.downcase.match(sample_match)
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
    samples = []  # Array of sample info hashes
    self.samples.each do |s|
      s = "#{self.path}/#{s}"
      samples << SampleInfo.create(s).info
    end
    sample_ids = Hash.new
    samples.each {|s| sample_ids[s["Id"]] = s["Filename"]} 

    # Read manifest and output sample information, getting filenames from the acutal directory, Descriptions and Locations from the manifest file
    f = File.new("#{self.path}/#{@manifest}","r")
    puts "reading manifest source: #{f.path}"
    f.each do |l|
        a = l.scan(/([^,"]*|".*?"),/)
        a.each_index do |i|
          next if a[i].class != Array
          a[i] = a[i][0]
          a[i] = a[i][1..-2] if a[i][0] == "\"" && a[i][-1] == "\""
        end 
       if sample_ids.has_key?(a[0])
          samples[samples.index{|x| x["Id"] == a[0]}]["Description"] = a[1] if !a[1].nil?
          samples[samples.index{|x| x["Id"] == a[0]}]["Location"] = a[2] if !a[2].nil?
       end
    end
    samples  
  end

  def generate_manifest
    manifest_template = ERB.new File.new("#{File.expand_path(File.dirname(__FILE__))}/audio_manifest.csv.erb").read, nil, "-"
    samples = []
    self.samples.each do |s|
      s = "#{self.path}/#{s}"
      samples << SampleInfo.create(s)
    end
    location = self
    vars = OpenStruct.new :location => location, :samples => samples
    doc = manifest_template.result(vars.send(:binding))
  end
  
  def playlist
    "samples.pls"
  end

  def generate_playlist
    output = "[playlist]\n"
    count = 0
    sample_info.each do |s|
      count += 1
      output += "File#{count}=#{File.basename(s["Filename"])}\n"
      output += "Title#{count}=#{s["Id"]} -- #{s["Description"]}\n"
    end
    output += "NumberOfEntries=#{count}"
    output
  end

end
