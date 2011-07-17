class SampleInfo
  attr_reader  :filename, :id, :creation_time, :creation_date, :file_format,
    :channels, :sample_rate, :bit_rate, :bits_per_sample, :bits, :duration

  def initialize(filename)
    file_found = File.exists?(filename)
    @filename = filename
    @id = File.basename(filename).sub(/\.[^\.]*$/,"") # tidied name of sample, with file extension removed
    @id = @id.sub(/^R09_0*/,"")    # remove Edirol standard prefix from file name, to make customisable at some point
    if file_found
      recording_time = File.mtime(filename)
      @creation_time = recording_time.strftime("%H:%M:%S")
      @creation_date = recording_time.strftime("%d %b %Y")
    end
    file_found
  end

  def self.create(filename)
    case filename.downcase
    when /.wav$/
      WavInfo.new(filename)
    when /.mp3$/
      Mp3Info.new(filename)
    else
      SampleInfo.new(filename)
    end
  end

  # Formats seconds to MM:SS.000
  def seconds_to_duration(secs)
    hours = "#{(secs/3600).to_i}:" if secs >= 3600
    "#{hours}#{Time.at(secs).strftime("%M:%S")}#{secs.to_s.match('\..{3}')}"
  end

# Sample Output format:
# Sample Name, Description, Location, Duration, Time, Date, Channels, Bitrate / BitsPerSample, Sample Rate, Format"
  def output_format
    [id, "", "", duration, creation_time, creation_date, channels, bits, sample_rate, file_format].join(",")
  end

  def info
    Hash["Filename" => filename, "Id" => id, "Description" => "", "Location" => "", "Duration" => duration, "Time" => creation_time, "Date" => creation_date, "Channels" => channels, "Bits" => bits, "Samplerate" => sample_rate, "Format" => file_format] 
  end

  def debug_output
    puts "ID: #{id}"
    puts "Filename: #{filename}"
    puts "File Type: #{file_format}"
    puts "Created: #{creation_time} on #{creation_date}"
    puts "Duration: #{duration}"
    puts "Channels: #{channels}, Sample Rate: #{sample_rate}"
    puts "BitRate: #{bit_rate} / Bits per sample: #{bits_per_sample}"
  end

end


# Wav parsing code based on:
# wavtweak.rb from Bill Kelly's post at: http://www.justskins.com/forums/process-wav-file-134461.html
# WAV format info at: http://www.borg.com/~jglatt/tech/wave.htm
# and: http://ccrma.stanford.edu/courses/422/projects/WaveFormat/

class WavInfo < SampleInfo
  PACK_FMT = "vvVVvv"

  def initialize(filename)
    @file_format = "WAV"
    if super
      File.open(filename, "r") do |f|
        f.binmode
        f.seek(0)
        parse_wav(f) do |file, chunk_name, chunk_len|
          case chunk_name
            when 'fmt' then handle_fmt_chunk(file, chunk_len)
            when 'data' then @duration = seconds_to_duration(length_in_seconds(chunk_len))
          end
        end
      end
    end
    @bits = @bits_per_sample
  end

  private	
  def parse_wav(file)
    riff, riff_len = read_chunk_header(file)
    raise NotRIFFFormat unless riff == 'RIFF'
    riff_end = file.tell + riff_len
    wave = file.read(4)
    raise NotWAVEFormat unless wave == 'WAVE'
    while file.tell < riff_end
      chunk_name, chunk_len = read_chunk_header(file)
      fpos = file.tell
      yield file, chunk_name, chunk_len if block_given?
      file.seek(fpos + chunk_len)
    end
  end
	
  def read_chunk_header(file)
    hdr = file.read(8)
    chunk_name, chunk_len = hdr.unpack("A4V")
  end

  def handle_fmt_chunk(file, chunk_len)
    fmt_dat_pos = file.tell
    @audio_format, @channels,
    @sample_rate, @byte_rate,
    @block_align, @bits_per_sample = file.read(chunk_len).unpack(PACK_FMT)
  end

  def length_in_seconds(chunk_length)
    # -8 bytes of chunk ID + size 
    secs=(chunk_length-8) / @channels / (@bits_per_sample / 8.0) / @sample_rate
  end
end

# mp3 header reading code
# based on c# code at http://www.devhood.com/tutorials/tutorial_details.aspx?tutorial_id=79
#   original C++ code by: Gustav "Grim Reaper" Munkby / http://floach.pimpin.net/grd/ / grimreaperdesigns@gmx.net
#   modified and converted to C# by: Robert A. Wlodarczyk / http://rob.wincereview.com:8080 / rwlodarc@hotmail.com
#   converted into Ruby by Charles Horn charles.horn@gmail.com
class Mp3Info < SampleInfo

  def initialize(filename)
    verbose = false
    @bit_header = 0
    @header_data = "0000"
    @file_format = "MP3"
    if super
      # Open file and parse, looking for a valid mp3 header, or ID3 tag
      File.open(filename, "r") do |f|
        @file_size = File.size(filename)
        f.binmode
        pos = 0
        while !valid_header? && pos < @file_size
          data = f.read(4)
          id3_info(data,f) if data[0,3] == "ID3" && verbose
          #data.each_byte {|c| puts "|#{c.chr.unpack("B8")}|"}
          #puts "File pos: #{f.pos}"
          header = load_mp3_header(data) if !data.nil?
          @bit_header = header if !data.nil?
          pos += 1
          f.seek(pos, IO::SEEK_SET)
        end
        @header_data = data if !data.nil?
      end
      
      display_mp3_info if verbose

      @duration = seconds_to_duration(length_in_seconds)
      @channels = channels
      @sample_rate = frequency
      @bit_rate = "#{bitrate}kb/s"
      @bits = @bit_rate
    end  
   end
  
  private  
  def load_mp3_header(byte_array)
    header = 0
    n = 24
    byte_array.each_byte do |c|
      header += c << n
      n -= 8
    end
    header
  end
  
  def get_id3_info(data, f)
    major_version = data[3,1]
    revision = f.read(1)
    puts "ID3 tag found, version: v2.#{major_version.ord}.#{revision.ord}"
  end
    
  def valid_header? 
    return (
      ((frame_sync      & 2047) == 2047) &&
      ((version_index   &    3) !=    1) &&
      ((layer_index     &    3) !=    0) && 
      ((bitrate_index   &   15) !=    0) &&
      ((bitrate_index   &   15) !=   15) &&
      ((frequency_index &    3) !=    3) &&
      ((emphasis_index  &    3) !=    2)    
    )
  end

  def frame_sync     
    @bit_header>>21 & 2047
  end

  def version_index
    @bit_header>>19 & 3
  end
  
  def layer_index
    @bit_header>>17 & 3 
  end

  def bitrate_index
    @bit_header>>12 & 15
  end
   
  def frequency_index
    @bit_header>>10 & 3
  end
  
  def mode_index
    @bit_header>>6 & 3
  end
  
  def emphasis_index
    @bit_header & 3
  end
   
  def bitrate
    table = [
      [ # MPEG 2 & 2.5
        [0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,0], # Layer III
        [0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,0], # Layer II
        [0, 32, 48, 56, 64, 80, 96,112,128,144,160,176,192,224,256,0]  # Layer I
      ],
      [ # MPEG 1
        [0, 32, 40, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,0], # Layer III
        [0, 32, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,384,0], # Layer II
        [0, 32, 64, 96,128,160,192,224,256,288,320,352,384,416,448,0]  # Layer I
      ]
    ]
    table[version_index & 1][layer_index - 1][bitrate_index]
  end
  
  def frequency
    table = [    
      [32000, 16000,  8000], # MPEG 2.5
      [    0,     0,     0], # reserved
      [22050, 24000, 16000], # MPEG 2
      [44100, 48000, 32000]  # MPEG 1
    ]
    table[version_index][frequency_index]
  end

  def mode
    case mode_index
      when 1
        "Joint Stereo"
      when 2
        "Dual Channel"
      when 3
        "Single Channel"
      else
        "Stereo"
    end
  end
  
  def channels
    mode_index == 3 ? 1 : 2
  end
  
  def length_in_seconds
    # get file size in 1000s of  bits (to match kb/s units)
    kb_size = 8.0 * @file_size / 1000
    kb_size / bitrate
  end

  def display_mp3_info
    @header_data .each_byte {|c| puts "|#{c.chr.unpack("B8")}|"}
    puts "Valid Header?: #{valid_header?}"
    puts "Bit Header: #{@bit_header}"
    puts "Version Index: #{version_index}"
    puts "Layer Index: #{layer_index}"
    puts "Bitrate Index: #{bitrate_index}"
    puts "Frequency Index; #{frequency_index}"
    puts "Bitrate: #{bitrate}kb/s"
    puts "Frequency: #{frequency}Hz"
    puts "Mode: #{mode}"
    puts "File Size: #{@file_size}"
    puts "Duration: #{seconds_to_duration(length_in_seconds)}"
  end
end
