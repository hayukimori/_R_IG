extends Node

static func is_valid_string(
    value: String,
    trim: bool = false,
    min_length: int = 1, 
    max_length: int = 50, 
    regex_pattern: String = ""
) -> bool:

    # Strip edges if trim is true
    value = value.strip_edges() if trim else value

    if value.length() < min_length or value.length() > max_length:
        return false
    if regex_pattern != "":
        var regex = RegEx.new()
        regex.compile(regex_pattern)
        if not regex.search(value):
            return false
    return true


# Validation for password
# Requirements:
#   - Minimum: 12 chars
#   - Includes 1 special character
#   - Includes 1 lower case character
#   - Includes 1 upper case character
#   - Includes 1 number
func validate_password(password: String) -> bool:
    # Setup validator for email (no regex)
    var validation = is_valid_string(
        password, 
        true,
        12, 255,
        r"^(?=.*[!@#%$^&()_+{}\\[\\]:;<>,.?/\\\\])(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z]).+$"
    )

    return validation


# Validation for Email
func validate_email(email: String) -> bool:
    # Setup validator for email
    var validation = is_valid_string(
        email, 
        true, 1, 255, 
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    )

    return validation 


# Validation for URL
func validate_url(url: String) -> bool:
    # Setup validation for url
    var validation = is_valid_string(
        url, 
        true, 1, 255, 
        r"^https?:\/\/(www\.)?[a-zA-Z0-9\-._~%]+(\.[a-zA-Z]{2,})(:[0-9]{1,5})?(\/[^\s]*)?$")

    return validation


# Validation for MongoDB ObjectId
func validate_object_id(object_id: String) -> bool:
    var validation: bool = is_valid_string(
        object_id,
        true, 24, 24,
        r"^[a-fA-F0-9]{24}$"
    )

    return validation


func validate_code(code: String) -> bool:
    var validation: bool = is_valid_string(
        code,
        true, 6, 6,
        r"^\d{6}$"
    )
    
    return validation