extends Node

var sound_library := {
    
}

func get_sound_by_name(sound_name: String) -> AudioStream:
    var sound_exists = sound_library.has(sound_name)
    if !sound_exists: 
        push_error("[SoundLib] Request sound %s does not exists in library" % sound_name)
        return null

    return sound_library.get(sound_library.get(sound_name))