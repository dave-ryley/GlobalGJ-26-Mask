extends Node2D

@export var scenarios : Array[PatientScenario]

var cur_scenario : PatientScenario
var cur_scenario_idx : int
var timer_callback : Callable

@export var custom_effects : Array[RichTextEffect] = [
	RichTextWait.new(),
	RichTextGhost.new(),
	RichTextMatrix.new()
	]
	
@export var robo_notes_theme : Theme

@export var client_audio : Array[AudioStream]

@onready var dialogue_box = $Control/DialogueBox
@onready var patient_info = $Control/PatientInfo
@onready var event_text = $Control/EventText
@onready var sequence_delay_timer = $SequenceDelay ## Used for timeline sequence delays
@onready var quit_box = $Control/QuitToMenu
@onready var options_box_container : DialogueSelection = $Control/DialogueOptions
@onready var robo_notes_container = $Control/ColorRect/ScrollContainer/RoboNotesContainer
@onready var typewriter_scroll = $Control/ColorRect/ScrollContainer
@onready var typewriter_audio = $TypewriterAudio
@onready var character_audio = $CharacterAudio

var robo_type_alpha = 0
var cur_robo_notes : RichTextLabel
var robo_type_speed = 1

func _on_sequence_delay_timeout() -> void:
	if not timer_callback.is_null():
		timer_callback.call()
	
func on_delay(delay_time, func_to_call):
	timer_callback = Callable(self, func_to_call)
	sequence_delay_timer.start(delay_time)
	
func hide_event_text():
	event_text.hide()

func _ready():
	quit_box.hide()
	event_text.hide()
	cur_scenario_idx = 0
	dialogue_box.set_external_options_container(options_box_container)
	try_setup_scenario(cur_scenario_idx)

func _process(delta: float) -> void:
	if cur_robo_notes:
		if robo_type_alpha < 1:
			robo_type_alpha = robo_type_alpha + (robo_type_speed * delta)
			robo_type_alpha = minf(1, robo_type_alpha)
			cur_robo_notes.visible_ratio = robo_type_alpha
			typewriter_scroll.scroll_vertical = 1000000000
			if robo_type_alpha >= 1:
				typewriter_audio.stop()
	
func try_setup_scenario(index : int) -> bool:
	if scenarios.size() > index :
		cur_scenario = scenarios[index]
		patient_info.clear()
		patient_info.push_color(cur_scenario.patient.color)
		patient_info.add_text(cur_scenario.patient.name)
		
		dialogue_box.data = cur_scenario.dialogue_data
		if not dialogue_box.is_running():
			dialogue_box.start("START")
		return true
	else:
		return false

func _on_dialogue_signal(value : String):
	match(value):
		'root_cause': discover_root_cause()
		'resolution_good': resolution_good()
		'resolution_bad': resolution_bad()
		
func discover_root_cause():
	event_text.show()
	event_text.text = "Discovered Root Cause!"
	on_delay(1, "hide_event_text")
	
func resolution_good():
	event_text.show()
	event_text.text = "Achieved Good Resolution!"
	on_delay(1, "end_scenario")
	
func resolution_bad():
	event_text.show()
	event_text.text = "Bad Resolution!"
	on_delay(1, "end_scenario")
	
func end_scenario():
	event_text.hide()
	cur_scenario_idx = cur_scenario_idx + 1
	if not try_setup_scenario(cur_scenario_idx):
		end_game()
	
func end_game():
	quit_box.show()
	event_text.show()
	event_text.text = "Game Over!"

func _on_quit_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu.tscn")

func _on_dialogue_processed(speaker: Variant, dialogue: String, options: Array[String], emotion : int, robo_notes_text : String) -> void:
	var speaker_name : String
	if speaker is Character:
		speaker_name = speaker.name
	elif speaker is String:
		speaker_name = speaker
	if speaker_name.contains("["): ## Indication of robo-advisor
		dialogue_box.anchor_left = 0
		dialogue_box.anchor_right = 0.5
		options_box_container.play_robo_audio(speaker_name)
	else:
		dialogue_box.anchor_left = 0.5
		dialogue_box.anchor_right = 1
		play_client_audio(emotion)

func _on_robo_notes_start(notes: String) -> void:
	if cur_robo_notes:
		if robo_type_alpha < 0:
			cur_robo_notes.visible_ratio = 1
			
	typewriter_audio.stop()
	typewriter_audio.play(0)
	var new_robo_notes = RichTextLabel.new()
	robo_notes_container.add_child(new_robo_notes)
	new_robo_notes.theme = robo_notes_theme
	new_robo_notes.text = notes
	new_robo_notes.bbcode_enabled = true
	new_robo_notes.size_flags_horizontal = Control.SIZE_FILL
	new_robo_notes.size_flags_vertical = Control.SIZE_SHRINK_END
	new_robo_notes.custom_effects = custom_effects
	new_robo_notes.visible_ratio = 0
	new_robo_notes.fit_content = true
	new_robo_notes.scroll_active = false
	new_robo_notes.scroll_following = true
	cur_robo_notes = new_robo_notes
	robo_type_alpha = 0
	
func play_client_audio(emotion : int):
	character_audio.stop()
	if emotion >= 0 and client_audio.size() > emotion:
		character_audio.stream = client_audio.get(emotion)
		character_audio.play(0)
