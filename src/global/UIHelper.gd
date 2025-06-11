extends Node
class_name UIHelper

static func add_hover_effect(button: Button, ignore_disabled: bool = true, scale: float = 1.05, duration: float = 0.2) -> void:
    if button == null:
        return
    button.mouse_entered.connect(func():
        if ignore_disabled and button.disabled:
            return
        var tween = button.create_tween()
        tween.tween_property(button, "scale", Vector2(scale, scale), duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    )
    button.mouse_exited.connect(func():
        var tween = button.create_tween()
        tween.tween_property(button, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    )

