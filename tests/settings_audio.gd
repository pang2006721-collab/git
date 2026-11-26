extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var settings = root.get_node("GameSettings")
	settings.save_path = "user://settings-audio-test.cfg"
	var old_music: float = settings.music_volume
	var old_sfx: float = settings.sfx_volume
	var bgm = root.get_node("Bgm")
	var bus := AudioServer.get_bus_index("BgmMusic")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus,capture)
	settings.set_music(0.8)
	settings.set_sfx(0.8)
	bgm.play_track(bgm.Track.MENU)
	await create_timer(3.5).timeout
	capture.clear_buffer()
	await create_timer(0.7).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in samples: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	var ok: bool = bgm._player.playing and not AudioServer.is_bus_mute(bus) and peak > 0.001
	print("MUSIC_PLAYING=",bgm._player.playing," BUS_GAIN=",AudioServer.get_bus_volume_linear(bus)," CAPTURE_FRAMES=",samples.size()," AUDIO_PEAK=",peak," DRIVER=",AudioServer.get_driver_name())
	settings.set_music(old_music)
	settings.set_sfx(old_sfx)
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	print("SETTINGS_AUDIO_FAILURES=",0 if ok else 1)
	quit(0 if ok else 1)
