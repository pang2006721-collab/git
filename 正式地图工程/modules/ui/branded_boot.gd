extends Node
## Reuse the black five-bean transition while loading the homepage in the background.
func _ready():_begin.call_deferred()
func _begin():
    var loading=preload("res://modules/cinematic/settlement_return_home.gd").new()
    loading.name="BootLoading"
    loading.fade_to_black_seconds=0.0
    loading.minimum_black_seconds=1.65
    loading.reveal_seconds=.65
    get_tree().root.add_child(loading)
    loading.black.color.a=1.0
    loading.start()
