extends Node

class MusicMetadata:
	var error: String
	var bpm: int
	var title: String
	var album: String
	var comments: String
	var year: int
	var artist: String
	var cover: ImageTexture
	
	func print_info():
		print("error: ", error)
		print("bpm: ", bpm)
		print("title: ", title)
		print("album: ", album)
		print("comments: ", comments)
		print("year: ", year)
		print("cover: ", cover)
		print("artist: ", artist)
		
func get_metadata_mp3(stream: AudioStreamMP3) -> MusicMetadata:
	var meta: MusicMetadata = MusicMetadata.new()
	var data: PackedByteArray = stream.data
	
	if data.size() < 10:
		meta.error = "NOT ID3"
		return meta
	var header = data.slice(0, 10)
	var id = header.slice(0, 3).get_string_from_ascii()
	if id != "ID3":
		meta.error = "NOT ID3"
		return meta
	var v = "ID3v2.%d.%d" % [header[3], header[4]]
	if v != "ID3v2.3.0":
		meta.error = v + "is not yet supposted :("
		return meta
	var flags = header[5]
	var _unsync = flags & 0x80 > 0
	var extended = flags & 0x40 > 0
	var _experimental = flags & 0x20 > 0
	var _has_footer = flags & 0x10 > 0
	var idx = 10
	var end = idx + bytes_to_int(header.slice(6, 10))
	if extended:
		idx += bytes_to_int(data.slice(idx, idx + 4))
	# Now idx points to the start of the first frame
	while idx < end:
		if not data:
			meta.error = "data null"
			return meta
		var frame_id = data.slice(idx, idx + 4).get_string_from_ascii()
		var size = bytes_to_int(data.slice(idx + 4, idx + 8), frame_id != "APIC")
		# if greater than byte, not sync safe number
		if size > 255:
			size = bytes_to_int(data.slice(idx + 4, idx + 8), false)
			
		idx += 10
		match frame_id:
			"TBPM":
				meta.bpm = int(get_string_from_data(data, idx, size))
			"TIT2":
				meta.title = get_string_from_data(data, idx, size)
			"TALB":
				meta.album = get_string_from_data(data, idx, size)
			"COMM":
				meta.comments = get_string_from_data(data, idx, size)
			"TYER":
				meta.year = int(get_string_from_data(data, idx, size))
			"TPE1":
				meta.artist = get_string_from_data(data, idx, size)
			"APIC":
				var pic_frame = data.slice(idx + 1, idx + size)
				var zero1 = pic_frame.find(0)
				if zero1 > 0:
					var mime_type = pic_frame.slice(0, zero1).get_string_from_ascii()
					zero1 += 1 # Picture type
					if zero1 < pic_frame.size():
						zero1 += 1
						if zero1 < pic_frame.size():
							var zero2 = pic_frame.find(0, zero1)
							var image_bytes = pic_frame.slice(zero2 + 1, pic_frame.size())
							var img = Image.new()
							var t: ImageTexture = ImageTexture.new()
							match mime_type:
								"image/png":
									img.load_png_from_buffer(image_bytes)
								"image/jpeg":
									img.load_jpg_from_buffer(image_bytes)
								_:
									printerr("MusicMeta.get_metadata_mp3(): ERROR: mime type ", mime_type, " not yet supported...")
									
							t.set_image(img)
							meta.cover = t
		idx += size
		
	return meta


func get_string_from_data(data, idx, size):
	var ret
	if size > 3 and Array(data.slice(idx, idx + 3)).hash() == [1, 0xff, 0xfe].hash():
		# Null-terminated string of ucs2 chars
		ret = get_string_from_ucs2(data.slice(idx + 3, idx + size))
	if data[idx] == 0:
		# Simple utf8 string
		ret = data.slice(idx + 1, idx + size).get_string_from_utf8()
	if ret:
		return ret
	else:
		return ""

# Syncsafe uses 0x80 multiplier otherwise use 0x100 multiplier
func bytes_to_int(bytes: Array, is_syncsafe = true):
	var mult = 0x80 if is_syncsafe else 0x100
	var n = 0
	for byte in bytes:
		n *= mult
		n += byte
	return n

func get_string_from_ucs2(bytes: Array):
	var s = ""
	var idx = 0
	while idx < (bytes.size() - 1):
		s += char(bytes[idx] + 256 * bytes[idx + 1])
		idx += 2
	return s
