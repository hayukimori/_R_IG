extends Node

var sound_library := {
    "alert0": preload("res://assets/audio/s1.wav"),
    "alert1": preload("res://assets/audio/alert1.wav")
}

func get_sound_by_name(sound_name: String) -> AudioStream:
    var sound_exists = sound_library.has(sound_name)
    if !sound_exists: 
        push_error("[SoundLib] Request sound %s does not exists in library" % sound_name)
        return null

    var sound = sound_library.get(sound_name)
    return sound