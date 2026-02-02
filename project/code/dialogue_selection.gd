extends VBoxContainer
class_name DialogueSelection

@onready var mask = $"../../Backdrop/Torso/ArmAnchor/Mask"
@onready var test_text : Label = $"../Label"
@onready var character_audio = $"../../CharacterAudio"
@onready var hover_sound = $"../../HoverSound"
@onready var click_sound = $"../../ClickSound"
@onready var change_mask_anim_player = $"../../ChangeMaskAnimation"

@export var robo_audio : Dictionary[String, AudioStream]
@export var mask_images : Dictionary[String, Texture2D]
var mask_labels : Array[String] = ["[happy]", "[sad]", "[blank]", "[stern]", "[joker]", "[diagnosis]"]
var cur_mask_label : String

func on_select(index : int):
	hover_sound.play(0)
	var child_button : Button = get_child(index)
	var match_found : bool = false
	for label in mask_labels:
		if child_button.text.containsn(label):
			test_text.text = label
			cur_mask_label = label
			match_found = true
			change_mask_anim_player.stop()
			change_mask_anim_player.play("ChangeMask")
	if not match_found:
		test_text.text = child_button.text

func on_click_option(index : int):
	click_sound.play(0)

func assign_selection_listeners():
	var children = get_children()
	for i in children.size():
		var option_button : Button = children[i]
		option_button.focus_entered.connect(func(): on_select(i))
		
func on_animation_mask_change():
	if not cur_mask_label.is_empty():
		mask.texture = mask_images.get(cur_mask_label)

func play_robo_audio(speaker : String):
	var audio_stream
	for label in mask_labels:
		if speaker.containsn(label):
			audio_stream = robo_audio.get(label)
	if audio_stream:
		character_audio.stop()
		character_audio.stream = audio_stream
		character_audio.play(0)
