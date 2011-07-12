$LOAD_PATH << "#{File.dirname($0)}/"
require "sample_info"
require "erb"
require 'ostruct'

# Creates a .CSV manifest in each subdirectory listing audio files
# USAGE:
#   ruby create_manifests.rb [./]
#

def generate_index(dir)
  index_template = ERB.new File.new("#{File.dirname($0)}/manifest_index.html.erb").read, nil, "-"
  vars = OpenStruct.new :location => location, :manifests => manifests
  doc = index_template.result(vars.send(:binding))
end

def generate_csv(dir)
  manifest_template = ERB.new File.new("#{File.dirname($0)}/audio_manifest.csv.erb").read, nil, "-"
  samples = []
  location = Dir.new(dir)
  location.sort.each do |f|
    samples << WavInfo.new("#{dir}/#{f}") if f.upcase.include?(".WAV")
    samples << Mp3Info.new("#{dir}/#{f}") if f.upcase.include?(".MP3")
  end
  vars = OpenStruct.new :location => location, :samples => samples
  doc = manifest_template.result(vars.send(:binding))
  manifest_name = "#{dir}/#{dir}_manifest.csv"
  if !File.exist?(manifest_name)
    if File.open(manifest_name, 'w') {|f| f.write(doc) }
      puts "Created #{manifest_name}!"
    end
  end
end

if ARGV[0].nil?
  location = Dir.new("./")
else
  location = Dir.new(ARGV[0])
end

# Get list of sub directories
sub_dirs = ["./"]
location.each do |x|
  sub_dirs << x if File.directory?(x) && x[0] != "."
end

# Check each sub dir for presence of a .csv manifest, otherwise create it.
sub_dirs.each do |sub|
  has_csv = false
  Dir.new(sub).each do |f|
    has_csv = true if File.file?("#{sub}/#{f}") && f.end_with?(".csv")
  end
  puts "Found CSV manifest in #{sub} ... skipping." if has_csv
  generate_csv("#{sub}") if !has_csv
end


