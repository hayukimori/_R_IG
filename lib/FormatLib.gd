class_name FormatLib

static func float_to_currency(value: float) -> String:
	return "R$ %.2f" % value

static func number_with_dots(number: int) -> String:
	var str_number = str(number)
	var result = ""
	for i in range(str_number.length()):
		if i > 0 and (str_number.length() - i) % 3 == 0:
			result += "."
		result += str_number[i]
	return result

static func format_number(value: int) -> String:
	var suffixes = ["T", "B", "M", "K"]
	var suffix_values = [1e12, 1e9, 1e6, 1e3]
	
	for i in range(suffixes.size()):
		var suffix_value = suffix_values[i]
		var suffix = suffixes[i]

		if abs(value) >= suffix_value:
			var formatted_value = round(value / suffix_value * 10.0) / 10.0
			
			return str(formatted_value) + suffix

	return str(value)

static func compare_dicts(dict_a: Dictionary, dict_b: Dictionary) -> Array:
	var differing_keys: Array = []
	var all_keys: Array = []

	for key in dict_a.keys():
		if not all_keys.has(key):
			all_keys.append(key)
	for key in dict_b.keys():
		if not all_keys.has(key):
			all_keys.append(key)

	# Compare values
	for key in all_keys:
		if not dict_a.has(key) or not dict_b.has(key):
			differing_keys.append(key)
		elif dict_a[key] != dict_b[key]:
			differing_keys.append(key)

	return differing_keys

