extends Node2D

@export var demo : DialogueData

@onready var dialogue_box = $Control/DialogueBox

func _ready():
	dialogue_box.data = demo

func _on_button_pressed() -> void:
	if not dialogue_box.is_running():
		dialogue_box.start("START")
