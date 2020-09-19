class_name GIFDataTypes
extends Reference


class GraphicControlExtension:
	var extension_introducer: int = 0x21
	var graphic_control_label: int = 0xf9

	var block_size: int = 4
	var packed_fields: int = 0b00001000
	var delay_time: int = 0
	var transparent_color_index: int = 0

	func _init(_delay_time: int,
			use_transparency: bool = false,
			_transparent_color_index: int = 0):
		delay_time = _delay_time
		transparent_color_index = _transparent_color_index
		if use_transparency:
			packed_fields = 0b00001001

	func to_bytes() -> PoolByteArray:
		var little_endian = preload('./little_endian.gd').new()
		var result: PoolByteArray = PoolByteArray([])

		result.append(extension_introducer)
		result.append(graphic_control_label)

		result.append(block_size)
		result.append(packed_fields)
		result += little_endian.int_to_word(delay_time)
		result.append(transparent_color_index)

		result.append(0)

		return result

class ImageDescriptor:
	var image_separator: int = 0x2c
	var image_left_position: int = 0
	var image_top_position: int = 0
	var image_width: int
	var image_height: int
	var packed_fields: int = 0b10000000

	func _init(_image_left_position: int,
			_image_top_position: int,
			_image_width: int,
			_image_height: int,
			size_of_local_color_table: int):
		image_left_position = _image_left_position
		image_top_position = _image_top_position
		image_width = _image_width
		image_height = _image_height
		packed_fields = packed_fields | (0b111 & size_of_local_color_table)

	func to_bytes() -> PoolByteArray:
		var little_endian = preload('./little_endian.gd').new()
		var result: PoolByteArray = PoolByteArray([])

		result.append(image_separator)
		result += little_endian.int_to_word(image_left_position)
		result += little_endian.int_to_word(image_top_position)
		result += little_endian.int_to_word(image_width)
		result += little_endian.int_to_word(image_height)
		result.append(packed_fields)

		return result

class LocalColorTable:
	var colors: Array = []

	func log2(value: float) -> float:
		return log(value) / log(2.0)

	func get_size() -> int:
		if colors.size() <= 1:
			return 0
		return int(ceil(log2(colors.size()) - 1))

	func to_bytes() -> PoolByteArray:
		var result: PoolByteArray = PoolByteArray([])

		for v in colors:
			result.append(v[0])
			result.append(v[1])
			result.append(v[2])

		if colors.size() != int(pow(2, get_size() + 1)):
			for i in range(int(pow(2, get_size() + 1)) - colors.size()):
				result += PoolByteArray([0, 0, 0])

		return result

class ApplicationExtension:
	var extension_introducer: int = 0x21
	var extension_label: int = 0xff

	var block_size: int = 11
	var application_identifier: PoolByteArray
	var appl_authentication_code: PoolByteArray

	var application_data: PoolByteArray

	func _init(_application_identifier: String,
			_appl_authentication_code: String):
		application_identifier = _application_identifier.to_ascii()
		appl_authentication_code = _appl_authentication_code.to_ascii()

	func to_bytes() -> PoolByteArray:
		var result: PoolByteArray = PoolByteArray([])

		result.append(extension_introducer)
		result.append(extension_label)
		result.append(block_size)
		result += application_identifier
		result += appl_authentication_code

		result.append(application_data.size())
		result += application_data

		result.append(0)

		return result

class ImageData:
	var lzw_minimum_code_size: int
	var image_data: PoolByteArray

	func to_bytes() -> PoolByteArray:
		var result: PoolByteArray = PoolByteArray([])
		result.append(lzw_minimum_code_size)

		var block_size_index: int = 0
		var i: int = 0
		var data_index: int = 0
		while data_index < image_data.size():
			if i == 0:
				result.append(0)
				block_size_index = result.size() - 1
			result.append(image_data[data_index])
			result[block_size_index] += 1
			data_index += 1
			i += 1
			if i == 254:
				i = 0

		if not image_data.empty():
			result.append(0)

		return result
