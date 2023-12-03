class_name Tweenframe extends Resource

@export var transform: Transform2D
@export var frame_num: int

enum EaseType {EASED, STEP, CURVE}
@export var ease_type: EaseType

@export_exp_easing() var ease_value: float = 1.0
@export var ease_curve: Curve


func _validate_property(property):
	match property.name:
		"ease_value":
			property.usage = PROPERTY_USAGE_DEFAULT if ease_type == EaseType.EASED else PROPERTY_USAGE_STORAGE
		"ease_curve":
			property.usage = PROPERTY_USAGE_DEFAULT if ease_type == EaseType.CURVE else PROPERTY_USAGE_NONE


func ease_t(t: float) -> float:
	match ease_type:
		EaseType.EASED:
			return ease(t, ease_value)
		EaseType.STEP:
			return 0.0
		EaseType.CURVE:
			return ease_curve.sample_baked(t)
	return t
