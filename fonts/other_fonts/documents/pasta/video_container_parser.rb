# -*- encoding: utf-8 -*-

# A Video Container parser which works closely with HTTPParser.
# Current supported container types are as follows.
# * MP4 (ISO/IEC 14496-12)
# * Adobe Flash Video File Format (Annex E)
# * MPEG-2 TS/TTS/PS (ISO/IEC 13818-1)
# Following container types are  currently out of support.
# * HLS (HTTP Live Streaming)
# * MPEG-1 System (ISO/IEC 11172-1)
module VideoContainerParser

  # Parse video container and return the result of parsed information.
  # The type of container is determined automatically.
  # @param  [String]  body  Reconstructed HTTP body.
  # @return [Array]   Return an array listing following information.
  # * [String]  video container
  # * [String]  video major brand
  # * [Float]   video duration (sec)
  # * [String]  video type
  # * [String]  video profile
  # * [Integer] video bitrate (bit/sec)
  # * [Integer] video width (pixel)
  # * [Integer] video height (pixel)
  # * [Integer] video horizontal resolution (pixel/inch)
  # * [Integer] video vertical resolution (pixel/inch)
  # * [String]  audio type
  # * [Integer] audio bitrate (bit/sec)
  # * [Integer] audio channel count (ch)
  # * [Integer] audio sample size (bit)
  # * [Integer] audio sample rate (Hz)
  def parse_video_container( body = nil )
    parsed = {}
    if body 
      begin
        parsed = parse_iso_base_media_file_format( body )
        parsed = parse_flv_format( body ) if parsed.empty?
        parsed = parse_mpeg2_file_format( body ) if parsed.empty?
      rescue
      end
    end
    [parsed['video_container'], parsed['video_major_brand'], parsed['video_duration'],
     parsed['video_type'], parsed['video_profile'], parsed['video_bitrate'], parsed['video_width'], parsed['video_height'], parsed['video_horizontal_resolution'], parsed['video_vertical_resolution'],
     parsed['audio_type'], parsed['audio_bitrate'], parsed['audio_channel_count'], parsed['audio_sample_size'], parsed['audio_sample_rate']]
  end

  private

  ISO_BASE_MEDIA_FILE_FORMAT_KEYWORDS = ['ftyp', 'pdin', 'moov', 'moof', 'mfra', 'mdat', 'free', 'skip', 'meta', 'uuid']
  ISO_BASE_MEDIA_FILE_FORMAT_VIDEO_TYPES = ['vide', 'mp4v', 'avc1', 'H264', 'h264', 'VP6F', 'VP6A', 'VP60', 'VP61', 'VP62', 'gif ', 'png ', 'jpeg', 's263']
  ISO_BASE_MEDIA_FILE_FORMAT_AUDIO_TYPES = ['soun', 'mp4a', 'samr', '.mp3', 'sawb', 'sawp', 'sevc', 'secb', 'secw', 'sqcp', 'ssmv', 'svmr']
  ISO_BASE_MEDIA_FILE_SOUND_FORMAT_ASSIGNMENTS = {
    'samr' => 'AMR',
    'mp4a' => 'AAC'
  }
  ISO_BASE_MEDIA_FILE_VIDEO_FORMAT_ASSIGNMENTS = {
    's263' => 'Sorenson H.263',
    'mp4v' => 'MPEG-4 Visual Simple Profile',
    'avc1' => 'H.264/MPEG-4 AVC'
  }
  ISO_BASE_MEDIA_FILE_VIDEO_PROFILES = {
    44  => 'CAVLC 4:4:4 Intra profile',
    66  => 'Baseline profile',
    77  => 'Main profile',
    83  => 'Scalable Baseline profile',
    86  => 'Scalable High profile',
    88  => 'Extended profile',
    100 => 'High profile',
    110 => 'High 10 profile',
    118 => 'Multiview High profile',
    122 => 'High 4:4:4 profile',
    128 => 'Stereo High profile',
    244 => 'High 4:4:4 Predictive profile'
  }

  def parse_iso_base_media_file_format_recursive( data )
    ptr = 0
    media_data_boxes = []
    loop do
      break if ptr >= data.size
      size = data[ptr...(ptr + 4)].unpack('N')[0]
      break if size.nil? or size == 0 or size == 1
      buf = data[(ptr + 4)...(ptr + size)]
      ptr += size
      media_data_box = {}
      case box_type = buf[0...4]
      when 'ftyp'
        media_data_box['box_type'] = box_type
        media_data_box['major_brand'] = buf[4...8]
        media_data_box['minor_version'] = buf[8...12].unpack('N')[0]
        media_data_box['compatible_brands'] = buf[12..-1]
      when 'moov', 'trak', 'mdia', 'minf', 'stbl'
        media_data_box['box_type'] = box_type
        media_data_box['boxes'] = parse_iso_base_media_file_format_recursive( buf[4..-1] )
      when 'mvhd'
        media_data_box['box_type'] = box_type
        media_data_box['version'] = buf[4...5].unpack('c')[0]
        media_data_box['time_scale'] = (media_data_box['version'] == 1 ? buf[24...28].unpack('N')[0] : buf[16...20].unpack('N')[0])
        media_data_box['duration'] = (media_data_box['version'] == 1 ? buf[28...36].unpack('Q')[0] : buf[20...24].unpack('N')[0])
      when 'stsd'
        media_data_box['box_type'] = box_type
        media_data_box['version'] = buf[4...5].unpack('c')[0]
        media_data_box['entry_count'] = buf[8...12].unpack('N')[0]
        media_data_box['boxes'] = parse_iso_base_media_file_format_recursive( buf[12..-1] )
      when *ISO_BASE_MEDIA_FILE_FORMAT_VIDEO_TYPES
        media_data_box['box_type'] = box_type
        media_data_box['width'] = buf[28...30].unpack('n')[0]
        media_data_box['height'] = buf[30...32].unpack('n')[0]
        media_data_box['horiz_resolution'] = buf[32...34].unpack('n')[0].to_f + buf[34...36].unpack('n')[0].to_f / (2 ** 16).to_f
        media_data_box['vert_resolution'] = buf[36...38].unpack('n')[0].to_f + buf[38...40].unpack('n')[0].to_f / (2 ** 16).to_f
        media_data_box['boxes'] = parse_iso_base_media_file_format_recursive( buf[82..-1] ) if box_type == 'avc1'
      when 'avcC'
        media_data_box['box_type'] = box_type
        media_data_box['version'] = buf[4...5].unpack('c')[0]
        media_data_box['profile'] = buf[5...6].unpack('c')[0] if media_data_box['version'] == 1
      when *ISO_BASE_MEDIA_FILE_FORMAT_AUDIO_TYPES
        media_data_box['box_type'] = box_type
        media_data_box['channel_count'] = buf[20...22].unpack('n')[0]
        media_data_box['sample_size'] = buf[22...24].unpack('n')[0]
        media_data_box['sample_rate'] = buf[28...30].unpack('n')[0].to_f + buf[30...32].unpack('n')[0].to_f / (2 ** 16).to_f
      end
      media_data_boxes << media_data_box unless media_data_box.empty?
    end
    media_data_boxes
  end

  def parse_iso_base_media_file_format( data )
    ret = {}
    return ret unless ISO_BASE_MEDIA_FILE_FORMAT_KEYWORDS.include? data[4...8]
    parsed = parse_iso_base_media_file_format_recursive( data )
    begin
      ftyp_box = parsed.each{|box| break box if box['box_type'] == 'ftyp'}
      ret['video_container'] = (ftyp_box['major_brand'] == 'f4v ' ? 'F4V' : 'MP4/AVC')
      ret['video_major_brand'] = ftyp_box['major_brand']
      mvhd_box = parsed.each{|box| break box['boxes'] if box['box_type'] == 'moov'}.each{|box| break box if box['box_type'] == 'mvhd'}
      ret['video_duration'] = mvhd_box['duration'] / mvhd_box['time_scale']
      parsed.each{|box| break box['boxes'] if box['box_type'] == 'moov'}.each do |box|
        if box['box_type'] == 'trak'
          begin
            box['boxes']
            .each{|box| break box['boxes'] if box['box_type'] == 'mdia'}
            .each{|box| break box['boxes'] if box['box_type'] == 'minf'}
            .each{|box| break box['boxes'] if box['box_type'] == 'stbl'}
            .each{|box| break box['boxes'] if box['box_type'] == 'stsd'}.each do |entry|
              if ISO_BASE_MEDIA_FILE_FORMAT_VIDEO_TYPES.include? entry['box_type']
                ret['video_type'] = ISO_BASE_MEDIA_FILE_VIDEO_FORMAT_ASSIGNMENTS[ entry['box_type'] ] || entry['box_type']
                ret['video_width'] = entry['width']
                ret['video_height'] = entry['height']
                ret['video_horizontal_resolution'] = entry['horiz_resolution']
                ret['video_vertical_resolution'] = entry['vert_resolution']
                begin
                  entry['boxes']
                  .each{|entry| break entry['boxes'] if entry['box_type'] == 'avc1'}.each do |lower_entry|
                    if lower_entry['box_type'] == 'avcC'
                      ret['video_profile'] = ISO_BASE_MEDIA_FILE_VIDEO_PROFILES[ lower_entry['profile'] ] || lower_entry['profile']
                    end
                  end
                rescue
                  next
                end
              elsif ISO_BASE_MEDIA_FILE_FORMAT_AUDIO_TYPES.include? entry['box_type']
                ret['audio_type'] = ISO_BASE_MEDIA_FILE_SOUND_FORMAT_ASSIGNMENTS[ entry['box_type'] ] || entry['box_type']
                ret['audio_channel_count'] = entry['channel_count']
                ret['audio_sample_size'] = entry['sample_size']
                ret['audio_sample_rate'] = entry['sample_rate']
              end
            end
          rescue
            next
          end
        end
      end
    rescue
      return ret
    end
    ret
  end

  FLV_SOUND_FORMAT_ASSIGNMENTS = {
     0 => 'Linear PCM, platform endian',
     1 => 'ADPCM',
     2 => 'MP3',
     3 => 'Linear PCM, little endian',
     4 => 'Nellymoser 16 kHz mono',
     5 => 'Nellymoser 8 kHz mono',
     6 => 'Nellymoser',
     7 => 'G.711 A-law logarithmic PCM',
     8 => 'G.711 mu-law logarithmic PCM',
     9 => 'reserved',
    10 => 'AAC',
    11 => 'Speex',
    14 => 'MP3 8 kHz',
    15 => 'Device-specific sound'
  }
  FLV_SOUND_RATE_ASSIGNMENTS = {
    0 =>  5_512.5,
    1 => 11_025,
    2 => 22_050,
    3 => 44_100
  }
  FLV_CODEC_ID_ASSIGNMENTS = {
    2 => 'Sorenson H.263',
    3 => 'Screen video',
    4 => 'On2 VP6',
    5 => 'On2 VP6 with alpha channel',
    6 => 'Screen video version 2',
    7 => 'H.264/MPEG-4 AVC'
  }
  def parse_flv_scriptdatavalue( data )
    type = data[0].unpack('C')[0]
    ptr = 1
    case type
    when 0
      value = data[ptr...(ptr + 8)].unpack('G')[0]; ptr += 8
    when 1
      value = data[ptr].unpack('C')[0]; ptr += 1
    when 2
      string_length = data[ptr...(ptr + 2)].unpack('n')[0]; ptr += 2
      value = data[ptr...(ptr + string_length)]; ptr += string_length
    when 3, 8
      if type == 8
        ecma_array_length = data[ptr...(ptr + 4)].unpack('N')[0]; ptr += 4
      end
      value = {}
      until data[ptr...(ptr + 3)].unpack('CCC') == [0, 0, 9]
        string_length = data[ptr...(ptr + 2)].unpack('n')[0]; ptr += 2
        string_data = data[ptr...(ptr + string_length)]; ptr += string_length
        size, property_data = parse_flv_scriptdatavalue( data[ptr..-1] ); ptr += size
        value[string_data] = property_data
      end
      ptr += 3
    when 7
      value = data[ptr...(ptr + 2)].unpack('n')[0]; ptr += 2
    when 10
      strict_array_length = data[ptr...(ptr + 4)].unpack('N')[0]; ptr += 4
      value = []
      strict_array_length.times do |i|
        size, property_data = parse_flv_scriptdatavalue( data[ptr..-1] ); ptr += size
        value << property_data
      end
    when 11
      value = {}
      value['data_time'] = data[ptr...(ptr + 8)].unpack('G')[0]; ptr += 8
      value['local_data_time_offsed'] = data[ptr...(ptr + 2)].unpack('n')[0]; ptr += 2
    when 12
      string_length = data[ptr...(ptr + 4)].unpack('N')[0]; ptr += 4
      value = data[ptr...(ptr + string_length)]; ptr += string_length
    end
    return ptr, value
  end

  def parse_flv_format( data )
    ret = {}
    skip_previous_tag_size_flg = false
    if data[0...3] == 'FLV'
      # flv header
      return ret unless ((flv_version = data[3].unpack('C')[0]) == 1)
      return ret unless ((data_offset = data[5...9].unpack('N')[0]) == 9)
    else
      # flv header none
      data_offset = 0
      return ret if (data_offset + 8 + 3) >= data.size
      #check Reserved
      return ret unless (data[data_offset].unpack('C')[0] & 0b11000000) == 0
      #check filter
      filter   = ((data[data_offset].unpack('C')[0] & 0b00100000) >> 5)
      return ret unless (filter == 0 || filter == 1)
      #check TagType
      tag_type = (data[data_offset].unpack('C')[0] & 0b00011111)
      return ret unless (tag_type == 8 || tag_type == 9 || tag_type == 18)
      #check StreamID
      return ret unless ((data[(data_offset + 8)...(data_offset + 8 + 3)].unpack('CCC')) == [0, 0, 0])
      skip_previous_tag_size_flg = true
    end
    prev_ptr = ptr = data_offset
    ret['video_container'] = 'FLV'
    loop do
      if skip_previous_tag_size_flg == false
        return ret if (ptr + 4) >= data.size
        return ret unless ((previous_tag_size = data[ptr...(ptr + 4)].unpack('N')[0]) == ptr - prev_ptr)
        ptr += 4
      else
        skip_previous_tag_size_flg = false
      end
      prev_ptr = ptr
      # flv file body
      filter   = ((data[ptr].unpack('C')[0] & 0b00100000) >> 5)
      tag_type = (data[ptr].unpack('C')[0] & 0b00011111)
      return ret if (ptr + 11) >= data.size
      ptr += 11
      # audio tag header
      if tag_type == 8
        sound_format = ((data[ptr].unpack('C')[0] & 0b11110000) >> 4)
        sound_rate   = ((data[ptr].unpack('C')[0] & 0b00001100) >> 2)
        sound_size   = ((data[ptr].unpack('C')[0] & 0b00000010) >> 1)
        sound_type   = (data[ptr].unpack('C')[0] & 0b00000001)
        ret['audio_type'] ||= FLV_SOUND_FORMAT_ASSIGNMENTS[sound_format]
        ret['audio_sample_rate'] ||= FLV_SOUND_RATE_ASSIGNMENTS[sound_rate]
        ret['audio_sample_size'] ||= (sound_size == 0 ? 8 : 16)
        ret['audio_channel_count'] ||= sound_type + 1
        ptr += 1
        ptr += 1 if sound_format == 10
      end
      # video tag header
      if tag_type == 9
        frame_type = ((data[ptr].unpack('C')[0] & 0b11110000) >> 4)
        codec_id   = (data[ptr].unpack('C')[0] & 0b00001111)
        ret['video_type'] ||= FLV_CODEC_ID_ASSIGNMENTS[codec_id]
        ptr += 1
        ptr += 4 if codec_id == 7
      end
      # encryption header and filter params
      if filter == 1
      end
      # audio/video data
      if tag_type == 8 or tag_type == 9
        while ((ptr + 4 < data.size) and (data[ptr...(ptr + 4)].unpack('N')[0] != ptr - prev_ptr)) do ptr += 1 end
      # script data
      elsif tag_type == 18
        size, tag_name = parse_flv_scriptdatavalue( data[ptr..-1] ); ptr += size
        size, tag_value = parse_flv_scriptdatavalue( data[ptr..-1] ); ptr += size
        if tag_name == "onMetaData"
          ret['video_duration']       ||= tag_value['duration']
          ret['video_type']           ||= FLV_CODEC_ID_ASSIGNMENTS[ tag_value['videocodecid'] ]
          ret['video_bitrate']        ||= tag_value['videodatarate'] * 1_000
          ret['video_width']          ||= tag_value['width']
          ret['video_height']         ||= tag_value['height']
          ret['audio_type']           ||= FLV_SOUND_FORMAT_ASSIGNMENTS[ tag_value['audiocodecid'] ]
          ret['audio_bitrate']        ||= tag_value['audiodatarate'] * 1_000
          ret['audio_channel_count']  ||= tag_value['stereo'].to_i + 1 if tag_value['stereo'].to_i
          ret['audio_sample_size']    ||= tag_value['audiosamplesize']
          ret['audio_sample_rate'] ||= tag_value['audiosamplerate']
        end
      end
    end
    ret
  end

  MPEG2_STREAM_TYPE_ASSIGNMENTS = {
      0 => "ITU-T | ISO/IEC Reserved",
      1 => "ISO/IEC 11172 Video",
      2 => "ITU-T Rec. H.262 | ISO/IEC 13818-2 Video or ISO/IEC 11172-2 constrained parameter video stream",
      3 => "ISO/IEC 11172 Audio",
      4 => "ISO/IEC 13818-3 Audio",
      5 => "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 private_sections",
      6 => "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 PES packets containing private data",
      7 => "ISO/IEC 13522 MHEG",
      8 => "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A DSM-CC",
      9 => "ITU-T Rec. H.222.1",
     10 => "ISO/IEC 13818-6 type A",
     11 => "ISO/IEC 13818-6 type B",
     12 => "ISO/IEC 13818-6 type C",
     13 => "ISO/IEC 13818-6 type D",
     14 => "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 auxiliary",
     15 => "ISO/IEC 13818-7 Audio with ADTS transport syntax",
     16 => "ISO/IEC 14496-2 Visual",
     17 => "ISO/IEC 14496-3 Audio with the LATM transport syntax as defined in ISO/IEC 14496-3 / AMD 1",
     18 => "ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in PES packets",
     19 => "ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in ISO/IEC14496_sections.",
     20 => "ISO/IEC 13818-6 Synchronized Download Protocol",
     21 => "METADATA IN PES",
     22 => "METADATA IN SECTION",
     23 => "METADATA IN DATA CAROUSEL",
     24 => "METADATA IN OBJECT CAROUSEL",
     25 => "METADATA IN DOWNLOAD PROTOCOL",
     26 => "IPRM STREAM",
     27 => "ITU T H264",
     28 => "ISO IEC 13818-1 RESERVED",
     29 => "USER PRIVATE",
    128 => "ISO IEC USER PRIVATE",
    129 => "DOLBY AC3 AUDIO",
    135 => "DOLBY DIGITAL PLUS AUDIO ATSC",
  }
  MPEG2_START_CODE_TABLE = {
      0 => "Picture", 
      1 => "Slice", 
    176 => "reserved", 
    178 => "User data", 
    179 => "Sequence", 
    180 => "Sequence Error", 
    181 => "Extension", 
    182 => "reserved", 
    183 => "Sequence End", 
    184 => "Group of Pictures(GOP)", 
    185 => "Program End", 
    186 => "Pack", 
    187 => "System", 
    188 => "Program Stream Map", 
    189 => "Private Stream1", 
    190 => "Padding Stream", 
    191 => "Private Stream2", 
    192 => "MPEG1/MPEG2 Audio Stream", 
    224 => "MPEG1/MPEG2 Video Stream", 
    240 => "ECM Stream", 
    241 => "EMM Stream", 
    242 => "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A or ISO/IEC 13818-6_DSMCC_stream", 
    243 => "ISO/IEC_13522_stream", 
    244 => "ITU-T Rec. H.222.1 type A", 
    245 => "ITU-T Rec. H.222.1 type B", 
    246 => "ITU-T Rec. H.222.1 type C", 
    247 => "ITU-T Rec. H.222.1 type D", 
    248 => "ITU-T Rec. H.222.1 type E", 
    249 => "Ancillary stream", 
    250 => "reserved", 
    253 => "VC-1, AC-3, DTS", 
    255 => "Program Stream Directory", 
  }
  AAC_AUDIO_PROFILE = {
    0 => "MAIN", 
    1 => "LC", 
    2 => "SSR", 
    3 => "reserved(LTP)", 
  }
  AAC_AUDIO_SAMPLERATE = {
    0 => 96000, 
    1 => 88200, 
    2 => 64000, 
    3 => 48000, 
    4 => 44100, 
    5 => 32000, 
    6 => 24000, 
    7 => 22050, 
    8 => 16000, 
    9 => 12000, 
    10 => 11025, 
    11 => 8000, 
  }
  MPEG2_AUDIO_VERSION = {
    0 => "ver 2.5", 
    1 => "reserved", 
    2 => "ver 2.0", 
    3 => "ver 1.0", 
  }
  MPEG2_AUDIO_LAYER = {
    0 => "reserved [AAC]", 
    1 => "layer 3", 
    2 => "layer 2", 
    3 => "layer 1", 
  }
  MPEG2_AUDIO_BITRATE = [
  ["reserved", "reserved", "reserved", "reserved", "reserved"], 
  [32000, 32000, 32000, 8000, 8000, 32000 ], 
  [40000, 48000, 64000, 16000, 16000, 48000 ], 
  [48000, 56000, 96000, 24000, 24000, 56000 ], 
  [56000, 64000, 128000, 32000, 32000, 64000 ], 
  [64000, 80000, 160000, 40000, 40000, 80000 ], 
  [80000, 96000, 192000, 48000, 48000, 96000 ], 
  [96000, 112000, 224000, 56000, 56000, 112000 ], 
  [112000, 128000000, 256000, 64000, 64000, 128000 ], 
  [128000, 160000, 288000, 80000, 80000, 144000 ], 
  [160000, 192000, 320000, 96000, 96000, 160000 ], 
  [192000, 224000, 352000, 112000, 112000, 176000 ], 
  [224000, 256000, 384000, 128000, 128000, 192000 ], 
  [256000, 320000, 416000, 144000, 144000, 224000 ], 
  [320000, 384000, 448000, 160000, 160000, 256000 ], 
  ["undefined", "undefined", "undefined", "undefined", "undefined" ], 
  ]
  MPEG2_AUDIO_SAMPLERATE = [
  [11025, 22050, 44100], 
  [12000, 24000, 48000], 
  [8000, 16000, 32000], 
  ["reserved", "reserved", "reserved"], 
  ]
  MPEG2_AUDIO_CH_MODE = {
    0 => 2, #"Stereo"
    1 => 2, #"Joint stereo"
    2 => 2, #"Dual channel"
    3 => 1, #"Single channel (Mono)"
  }
  MPEG2_AUDIO_EX_CH_MODE = {
    0 => "4 and over", 
    1 => "8 and over", 
    2 => "12 and over", 
    3 => "16 and over", 
  }
  AC3_AUDIO_SAMPLERATE = {
    0 => 48000, 
    1 => 44100, 
    2 => 32000, 
    3 => "reserved", 
  }
  AC3_AUDIO_BITRATE = {
     0 =>  32000,  1 =>  32000, 
     2 =>  40000,  3 =>  40000, 
     4 =>  48000,  5 =>  48000, 
     6 =>  56000,  7 =>  56000, 
     8 =>  64000,  9 =>  64000, 
    10 =>  80000, 11 =>  80000, 
    12 =>  96000, 13 =>  96000, 
    14 => 112000, 15 => 112000, 
    16 => 128000, 17 => 128000, 
    18 => 160000, 19 => 160000, 
    20 => 192000, 21 => 192000, 
    22 => 224000, 23 => 224000, 
    24 => 256000, 25 => 256000, 
    26 => 320000, 27 => 320000, 
    28 => 384000, 29 => 384000, 
    30 => 448000, 31 => 448000, 
    32 => 512000, 33 => 512000, 
    34 => 576000, 35 => 576000, 
    36 => 640000, 37 => 640000, 
  }
  AC3_AUDIO_BITSTREAM_MODE = {
    0 => "main audio service: complete main (CM)", 
    1 => "main audio service: music and effects (ME)", 
    2 => "associated service: visually impaired (VI)", 
    3 => "associated service: hearing impaired (HI)", 
    4 => "associated service: dialog (D)", 
    5 => "associated service: commentary (C)", 
    6 => "associated service: emergency (E)", 
  }
  AC3_AUDIO_CODING_MODE_TABLE = {
    0 => 2, #"1+1 Ch1, Ch2"
    1 => 1, #"1/0 C"
    2 => 2, #"2/0 L, R"
    3 => 3, #"3/0 L, C, R"
    4 => 3, #"2/1 L, R, S"
    5 => 4, #"3/1 L, C, R, S"
    6 => 4, #"2/2 L, R, SL, SR"
    7 => 5, #"3/2 L, C, R, SL, SR"
  }
  MPEG_VIDEO_ASPECT_FRAMERATE_TABLE = [
  ["forbidden", "forbidden"], 
  [1.0, 23.976], #"1.0 (1:1)", "23.976 (24000/1001)"
  [0.6735, 24], #"0.6735 (4:3)", "24"
  [0.7031, 25], #"0.7031 (16:9)", "25"
  [0.7615, 29.97], #"0.7615 (2.21:1)", "29.97 (30000/1001)"
  [0.8055, 30], #"0.8055", "30"
  [0.8437, 50], #"0.8437", "50"
  [0.8935, 59.94], #"0.8935", "59.94 (60000/1001)"
  [0.9157, 60], #"0.9157", "60"
  [0.9815, "reserved"], #"0.9815", "reserved"
  [1.0255, "reserved"], #"1.0255", "reserved"
  [1.0695, "reserved"], #"1.0695", "reserved"
  [1.095, "reserved"], #"1.095", "reserved"
  [1.1575, "reserved"], #"1.1575", "reserved"
  [1.2051, "reserved"], #"1.2051", "reserved"
  ["reserved", "reserved"], 
  ]
  MPEG_VIDEO_CHROMA_FORMAT_TABLE = {
    0 => "reserved", 
    1 => "4:2:0", 
    2 => "4:2:2", 
    3 => "4:4:4", 
  } 
  def get_elementary_info(header_type, ele_data, ele_pid, start_pos, mpeg2_info_hash)
    ac3_frame_code = ["0B77"].pack('H*')
  
    case MPEG2_START_CODE_TABLE[header_type]
      when "MPEG1/MPEG2 Audio Stream"
        if mpeg2_info_hash['payload_unit_start_indicator'] > 0 and ele_data[start_pos + 9] != nil
          opt_flg = (ele_data[start_pos + 6].unpack('C')[0] & 0b11000000) >> 6
          pts_dts_flg = (ele_data[start_pos + 7].unpack('C')[0] & 0b11110000) >> 6
          pts_dts_id = (ele_data[start_pos + 9].unpack('C')[0] & 0b11110000) >> 4
          if opt_flg == 2 and pts_dts_flg.between?(1, 3) and pts_dts_id.between?(0, 3)
            pts_dts_length = 1 if pts_dts_flg == 0
            pts_dts_length = 5 if pts_dts_flg == 2
            pts_dts_length = 10 if pts_dts_flg == 3

            pes_header_length = (ele_data[start_pos + 8].unpack("H*")[0].hex)

            mpeg_audio_layer = (ele_data[start_pos + 9 + pes_header_length + 1].unpack('C')[0] & 0b00000110) >> 1
            if mpeg_audio_layer == 0
              aac_audio_version = (ele_data[start_pos + 9 + pes_header_length + 1].unpack('C')[0] & 0b00001000) >> 3
              aac_audio_profile = (ele_data[start_pos + 10 + pes_header_length + 1].unpack('C')[0] & 0b11000000) >> 6
              aac_audio_smplrate = (ele_data[start_pos + 10 + pes_header_length + 1].unpack('C')[0] & 0b00111100) >> 2
              aac_audio_ch = ((ele_data[start_pos + 10 + pes_header_length + 1].unpack('C')[0] & 0b00000001) << 2) + ((ele_data[start_pos + 11 + pes_header_length + 1].unpack('C')[0] & 0b11000000) >> 6)

              # aac audio channel
              mpeg2_info_hash['aac_audio_info']["#{ele_pid}"][1] =  aac_audio_ch
              # aac audio samplerate
              mpeg2_info_hash['aac_audio_info']["#{ele_pid}"][3] =  AAC_AUDIO_SAMPLERATE[aac_audio_smplrate] != nil ? AAC_AUDIO_SAMPLERATE[aac_audio_smplrate] : "-"
              # aac audio version
              mpeg2_info_hash['aac_audio_info']["#{ele_pid}"][4] =  aac_audio_version == 0 ? "MPEG4" : "MPEG2"
              # aac audio layer
              mpeg2_info_hash['aac_audio_info']["#{ele_pid}"][5] = 0
              # aac audio profile
              mpeg2_info_hash['aac_audio_info']["#{ele_pid}"][6] =  AAC_AUDIO_PROFILE[aac_audio_profile]
            else
              mpeg_audio_version = (ele_data[start_pos + 9 + pes_header_length + 1].unpack('C')[0] & 0b00011000) >> 3
              mpeg_audio_bitrate = (ele_data[start_pos + 10 + pes_header_length + 1].unpack('C')[0] & 0b11110000) >> 4
              mpeg_audio_smplrate = (ele_data[start_pos + 10 + pes_header_length + 1].unpack('C')[0] & 0b00001100) >> 2
              mpeg_audio_ch_mode = (ele_data[start_pos + 11 + pes_header_length + 1].unpack('C')[0] & 0b11000000) >> 6
              mpeg_audio_ex_ch_mode = (ele_data[start_pos + 11 + pes_header_length + 1].unpack('C')[0] & 0b00110000) >> 4

              # mepg audio bit rate
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][0] =  mpeg_audio_version == 3 ? MPEG2_AUDIO_BITRATE[mpeg_audio_bitrate][mpeg_audio_layer - 1] : MPEG2_AUDIO_BITRATE[mpeg_audio_bitrate][mpeg_audio_layer + 2]
              # mepg audio channel mode
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][1] = MPEG2_AUDIO_CH_MODE[mpeg_audio_ch_mode]
              # mepg audio sample rate
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][3] = MPEG2_AUDIO_SAMPLERATE[mpeg_audio_smplrate][mpeg_audio_version - 1]
              # mepg audio version
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][4] =  MPEG2_AUDIO_VERSION[mpeg_audio_version]
              # mepg audio layer
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][5] = MPEG2_AUDIO_LAYER[mpeg_audio_layer]
              # mepg audio ex channel mode
              mpeg2_info_hash['mpeg_audio_info']["#{ele_pid}"][6] = MPEG2_AUDIO_EX_CH_MODE[mpeg_audio_ex_ch_mode]
            end
          end
        end

      when "VC-1, AC-3, DTS", "Private Stream1"
        ac3_start_pos = ele_data.index( ac3_frame_code )
        if ac3_start_pos != nil
          # dolby digital audio
          ac3_smplrate = (ele_data[ac3_start_pos + 4].unpack('C')[0] & 0b11000000) >> 6
          ac3_bitrate =  (ele_data[ac3_start_pos + 4].unpack('C')[0] & 0b00111111)
          ac3_bitstrm_version =  (ele_data[ac3_start_pos + 5].unpack('C')[0] & 0b11111000) >> 3
          ac3_bitstrm_mode =  (ele_data[ac3_start_pos + 5].unpack('C')[0] & 0b00000111)
          ac3_coding_mode =  (ele_data[ac3_start_pos + 6].unpack('C')[0] & 0b11100000) >> 5

          # ac3 audio bitrate
          mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][0] =  AC3_AUDIO_BITRATE[ac3_bitrate] != nil ? AC3_AUDIO_BITRATE[ac3_bitrate] : "reserved"
          # ac3 coding mode ch num
          mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][1] = AC3_AUDIO_CODING_MODE_TABLE[ac3_coding_mode]
          # ac3 audio sample size
          mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][2] = 16
          # ac3 audio sample rate
          mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][3] = AC3_AUDIO_SAMPLERATE[ac3_smplrate]
          # ac3 bitstream mode
          if AC3_AUDIO_BITSTREAM_MODE[ac3_bitstrm_mode] != nil
            mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][4] = AC3_AUDIO_BITSTREAM_MODE[ac3_bitstrm_mode]
          elsif ac3_coding_mode == 1
            mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][4] = "associated service: voice over (VO)"
          else
            mpeg2_info_hash['ac3_audio_info']["#{ele_pid}"][4] = "main audio service: karaoke"
          end
        end

      when "Sequence"
        if ele_data[start_pos + 11] != nil
          # mpeg video bit rate
          mpeg_video_bitrate = (ele_data[(start_pos + 8)..(start_pos + 10)].unpack('H*')[0]).hex >> 6
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][1] = mpeg_video_bitrate * 400
          # mpeg video holizon/ vertical
          mpeg_video_horizontal = (ele_data[(start_pos + 4)..(start_pos + 5)].unpack("H*")[0]).hex >> 4
          mpeg_video_vertical = ele_data[(start_pos + 5), 2].unpack('n')[0] % (2 ** 12)
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][2] = mpeg_video_horizontal
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][3] = mpeg_video_vertical
          # mpeg video acpect/ frame rate
          mpeg_video_aspect = (ele_data[(start_pos + 7)].unpack('C')[0] & 0b11110000) >> 4
          mpeg_video_framerate = (ele_data[(start_pos + 7)].unpack('C')[0] & 0b00001111)

          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][4] = MPEG_VIDEO_ASPECT_FRAMERATE_TABLE[ mpeg_video_aspect ][0]
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][5] = MPEG_VIDEO_ASPECT_FRAMERATE_TABLE[ mpeg_video_framerate ][1]
        end
                  
      when "Extension"
      # mpeg video picture coding type
        if ( (ele_data[start_pos + 4].unpack('C')[0] & 0b11110000) >> 4 ) == 1
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][6] = ( (ele_data[start_pos + 5].unpack('C')[0] & 0b00001000) ) > 0 ? "Progressive" : "Interlace"
          mpeg_video_chroma_format = ( ele_data[start_pos + 5].unpack('C')[0] & 0b00000110 ) >> 1
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][7] = MPEG_VIDEO_CHROMA_FORMAT_TABLE[ mpeg_video_chroma_format ]
        end

      when "Group of Pictures(GOP)"
        if ele_data[start_pos + 7] != nil
          mpeg_time_hour = (ele_data[start_pos + 4].unpack('C')[0] & 0b01111100) >> 2
          mpeg_time_min = ((ele_data[start_pos + 4].unpack('C')[0] & 0b00000011) << 4) + ((ele_data[start_pos + 5].unpack('C')[0] & 0b11110000) >> 4)
          mpeg_time_sec = ((ele_data[start_pos + 5].unpack('C')[0] & 0b00000111) << 3) + ((ele_data[start_pos + 6].unpack('C')[0] & 0b11100000) >> 5)

          if mpeg2_info_hash['play_time_info'].size == 0
            mpeg2_info_hash['play_time_info'][0] = mpeg_time_hour
            mpeg2_info_hash['play_time_info'][1] = mpeg_time_min
            mpeg2_info_hash['play_time_info'][2] = mpeg_time_sec
          end
          mpeg_time_hour = (mpeg_time_hour - mpeg2_info_hash['play_time_info'][0]) * 3600
          mpeg_time_min = (mpeg_time_min - mpeg2_info_hash['play_time_info'][1]) * 60
          mpeg_time_sec = mpeg_time_sec - mpeg2_info_hash['play_time_info'][2]
  
          mpeg2_info_hash['mpeg_video_info']["#{ele_pid}"][0] = mpeg_time_hour + mpeg_time_min + mpeg_time_sec
        end
    end
  end
  
  def parse_mpeg2_file_format( data )
    ret = {}
    pmt_info = Hash.new
    stream_info = Array.new
    elementary_info = Array.new
    mpeg2_info_hash = Hash.new
    mpeg_audio_info = Hash.new { |hash,key| hash[key] = [] }
    ac3_audio_info = Hash.new { |hash,key| hash[key] = [] }
    aac_audio_info = Hash.new { |hash,key| hash[key] = [] }
    mpeg_video_info = Hash.new { |hash,key| hash[key] = [] }
    play_time_info = Array.new

    mpeg2_start_code = ["000001"].pack('H*')

    [188, 192, 208].each do |cycle|
      sync_byte = 0x47.chr
      pos = 0
      while pos < cycle
        break unless pos = data.index( sync_byte, pos )
        sync = true; (1..5).each{|i| sync = false unless data[pos + i * cycle] == sync_byte}
        if sync
          ret['video_container'] = 'MPEG-2 TS'
          # as once synchronized, search for PSI data keeping synchronized
          while data[pos + 5 * cycle] == sync_byte
            payload_unit_start_indicator = (data[pos + 1].unpack('C')[0] & 0b11110000) >> 6
            packet_id = data[(pos + 1), 2].unpack('n')[0] % (2 ** 13)
            adaptation_field_ctrl = (data[pos + 3].unpack('C')[0] & 0b11110000) >> 4
            adaptation_field_length = adaptation_field_ctrl == ( 2 or 3) ? data[pos + 4].unpack('C')[0] + 1 : adaptation_field_length = 0
            adaptation_field_offset = adaptation_field_length + payload_unit_start_indicator

            # get PMT PID from PAT
            if packet_id == 0
              pat_section_length = data[pos + 4 + adaptation_field_offset + 1, 2].unpack('n')[0] % (2 ** 12)
              pmt_info_num = (pat_section_length - 9) / 4
              next_pmt = 0

              pmt_info_num.times{
                program_num = data[(pos + 4 + adaptation_field_offset + 8 + next_pmt)..(pos + 4 + adaptation_field_offset + 9 + next_pmt)].unpack('H*')[0].hex
                pm_pid  = data[pos + 4 + adaptation_field_offset + 10 + next_pmt, 2].unpack('n')[0] % (2 ** 13)
                pmt_info[program_num] = pm_pid
                next_pmt = next_pmt + 4
              }
            end

            pmt_info.values.each{ |pmt_val|            
              if packet_id == pmt_val and data[pos + 4 + adaptation_field_offset].unpack("H*")[0] == "02"
                next_stream = 0
                pmt_section_length = data[pos + 4 + adaptation_field_offset + 1, 2].unpack('n')[0] % (2 ** 12)
                program_info_length = data[pos + 4 + adaptation_field_offset + 10 + 1].unpack("H*")[0].hex

                until (17 + program_info_length + next_stream) > pmt_section_length do
                  stream_type = data[pos + 16 + adaptation_field_offset + program_info_length + next_stream].unpack("H*")[0].hex
                  elementary_pid = data[pos + 17 + adaptation_field_offset + program_info_length + next_stream, 2].unpack('n')[0] % (2 ** 13)
                  es_info_length = data[pos + 19 + adaptation_field_offset + program_info_length + next_stream, 2].unpack('n')[0] % (2 ** 12)

                  stream_info << stream_type
                  elementary_info << elementary_pid
                  next_stream = next_stream + 5 + es_info_length
                end
              end
            }

            stream_info.uniq.each{ |strm_type|
              case strm_type
              when 1, 2, 16, 27
                type = "video_type"
              when 3, 4, 15, 17, 129
                type = "audio_type"
              else
                type = "else_type"
                ret["else_type"] = strm_type.between?(21, 127) ? "ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Reserved" : "User Private"
              end
              ret[type] = MPEG2_STREAM_TYPE_ASSIGNMENTS[strm_type]
            }

            ele_data = data[pos .. (pos + cycle )]
            
            elementary_info.uniq.each{ |ele_pid|
              if packet_id == ele_pid
                start_pos = 0
                while start_pos < ele_data.size
                  break unless start_pos = ele_data.index( mpeg2_start_code, start_pos)
                  header_type = ele_data[start_pos + 3].unpack("H*")[0].hex

                  header_type = 1 if header_type.between?(2, 175)
                  header_type = 176 if header_type == 177
                  header_type = 192 if header_type.between?(193, 223)
                  header_type = 224 if header_type.between?(225, 239)
                  header_type = 250 if header_type.between?(251, 252)

                  mpeg2_info_hash = {"payload_unit_start_indicator" => payload_unit_start_indicator, "mpeg_audio_info" => mpeg_audio_info, 
                  "ac3_audio_info" => ac3_audio_info, "aac_audio_info" => aac_audio_info, 
                  "mpeg_video_info"=>mpeg_video_info, "play_time_info" => play_time_info}
                  
                  get_elementary_info(header_type, ele_data, ele_pid, start_pos, mpeg2_info_hash)
                  
                  start_pos += 1
                end

                if mpeg_video_info["#{ele_pid}"].size != 0
                  ret['video_duration'] = mpeg_video_info["#{ele_pid}"][0]
                  ret['video_bitrate'] = mpeg_video_info["#{ele_pid}"][1]
                  ret['video_width'] = mpeg_video_info["#{ele_pid}"][2]
                  ret['video_height'] = mpeg_video_info["#{ele_pid}"][3]
                end

                if ac3_audio_info["#{ele_pid}"].size != 0
                  ret['audio_bitrate'] = ac3_audio_info["#{ele_pid}"][0]
                  ret['audio_channel_count'] = ac3_audio_info["#{ele_pid}"][1]
                  ret['audio_sample_size'] = ac3_audio_info["#{ele_pid}"][2]
                  ret['audio_sample_rate'] = ac3_audio_info["#{ele_pid}"][3]
                elsif mpeg_audio_info["#{ele_pid}"].size != 0
                  ret['audio_bitrate'] = mpeg_audio_info["#{ele_pid}"][0]
                  ret['audio_channel_count'] = mpeg_audio_info["#{ele_pid}"][1]
                  ret['audio_sample_rate'] = mpeg_audio_info["#{ele_pid}"][3]
                elsif aac_audio_info["#{ele_pid}"].size != 0
                  ret['audio_channel_count'] = aac_audio_info["#{ele_pid}"][1]
                  ret['audio_sample_rate'] = aac_audio_info["#{ele_pid}"][3]
                end
              end #if packet_id == ele_pid
            }
            pos += cycle
          end #while data[pos + 5 * cycle] == sync_byte
        else #if sync
          pos += 1
        end #if sync
      end #while pos < cycle
    end #[188, 192, 208].each do
    return ret
  end #def parse_mpeg2_file_format
  
end
