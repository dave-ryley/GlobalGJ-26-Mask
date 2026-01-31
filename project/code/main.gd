extends Node2D

@export var scenarios : Array[PatientScenario]

var cur_scenario : PatientScenario
var cur_scenario_idx : int
var timer_callback : Callable

@onready var dialogue_box = $Control/DialogueBox
@onready var patient_info = $Control/PatientInfo
@onready var event_text = $Control/EventText
@onready var sequence_delay_timer = $SequenceDelay ## Used for timeline sequence delays
@onready var quit_box = $Control/QuitToMenu
@onready var options_box_container = $Control/DialogueOptions

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

func _on_dialogue_processed(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	var speaker_name : String
	if speaker is Character:
		speaker_name = speaker.name
	elif speaker is String:
		speaker_name = speaker
	if speaker_name.contains("["): ## Indication of robo-advisor
		dialogue_box.anchor_left = 0
		dialogue_box.anchor_right = 0.5
	else:
		dialogue_box.anchor_left = 0.5
		dialogue_box.anchor_right = 1
