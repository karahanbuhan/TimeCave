extends Node2D

onready var TENS = $Tens
onready var ONES = $Ones

export var frame_offset = 1
export var shut_off = false

var water_seconds = 0

signal time_ran_out

func _process(_delta):
	var secs = get_tree().get_root().find_node("Player", true, false).timer

	if secs == 0:
		TENS.frame = 1
		ONES.frame = 1
	elif secs < 0:
		shut_off = true
		
		TENS.frame = 0
		ONES.frame = 0		
	elif secs >= 90:
		TENS.frame = 9 + frame_offset
	elif secs >= 80:
		TENS.frame = 8 + frame_offset
	elif secs >= 70:
		TENS.frame = 7 + frame_offset
	elif secs >= 60:
		TENS.frame = 6 + frame_offset
	elif secs >= 50:
		TENS.frame = 5 + frame_offset
	elif secs >= 40:
		TENS.frame = 4 + frame_offset
	elif secs >= 30:
		TENS.frame = 3 + frame_offset
	elif secs >= 20:
		TENS.frame = 2 + frame_offset
	elif secs >= 10:
		TENS.frame = 1 + frame_offset
	else:
		TENS.frame = 0 + frame_offset

	ONES.frame = (secs % 10) + frame_offset
