extends VBoxContainer
class_name DialogueSelection

@onready var mask = $"../../Mask"
@onready var test_text : Label = $"../Label"

var mask_labels : Array[String] = ["[happy]", "[sad]", "[blank]", "[stern]", "[joker]", "[diagnosis]"]

func on_select(index : int):
	var child_button : Button = get_child(index)
	var match_found : bool = false
	for label in mask_labels:
		if child_button.text.containsn(label):
			test_text.text = label
			match_found = true
			break
	if not match_found:
		test_text.text = child_button.text

func assign_selection_listeners():
	var children = get_children()
	for i in children.size():
		var option_button : Button = children[i]
		option_button.focus_entered.connect(func(): on_select(i))
