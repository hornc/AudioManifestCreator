$LOAD_PATH << "#{File.dirname($0)}/"
require "sample_info"
require "audio_dir"
require "erb"
require 'ostruct'

# Creates a .CSV manifest in each subdirectory listing audio files
# USAGE:
#   ruby create_manifests.rb [./]
#

def generate_index(location, directories)
  index_template = ERB.new File.new("#{File.dirname($0)}/manifest_index.html.erb").read, nil, "-"
  vars = OpenStruct.new :location => location, :directories => directories
  doc = index_template.result(vars.send(:binding))
end

if ARGV[0].nil? || !File.directory?(ARGV[0])
  location = Dir.new("./")
else
  location = Dir.new(ARGV[0])
end

# Get list of sub directories (that contain audio files)
audio_dirs = [AudioDir.new(location)]
audio_files = /.*mp3|.*wav/ # set the pattern of samples we are interested in
location.each do |x|
  if File.directory?(x) && x[0] != "."
    audio_dirs << AudioDir.new(x, audio_files)
    audio_dirs.pop if !audio_dirs.last.has_samples?
  end
end

# Check each Audio directory for presence of a .csv manifest, otherwise generate it.
audio_dirs.each do |d|
  if d.has_manifest?
    puts "Found CSV manifest in #{d.path} ... skipping."
  else
    filename = "#{d.path}/#{d.manifest}"
    if File.open(filename, 'w') {|f| f.write(d.generate_manifest) }
      puts "Created #{filename}!"
    end
  end
end

if File.open("#{location.path}/index.html", 'w') {|f| f.write(generate_index(location, audio_dirs)) }
  puts "Created #{location.path}/index.html "
end
 

