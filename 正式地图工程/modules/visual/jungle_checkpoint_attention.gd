extends "res://modules/visual/checkpoint_attention.gd"
func _can_show()->bool:
    return not checkpoint.active and not checkpoint.level.dead and not checkpoint.level.exit_in_progress and checkpoint.level.player==checkpoint.body and checkpoint.body.get_node("Host").claimed and checkpoint.body.global_position.distance_to(checkpoint.global_position)<show_distance
