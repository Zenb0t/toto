class_name Spread
extends RefCounted
## Evenly fans a number of shots across an angle, centred on the aim direction.


## Angles in degrees, relative to the aim. One shot always flies straight.
static func angles_degrees(count: int, spread_degrees: float) -> Array[float]:
	var angles: Array[float] = []
	if count <= 1:
		angles.append(0.0)
		return angles
	for index in count:
		angles.append(lerpf(-spread_degrees / 2.0, spread_degrees / 2.0, float(index) / (count - 1)))
	return angles
