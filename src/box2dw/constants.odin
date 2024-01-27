package box2d

// box2d bases all length units on meters, but you may need different units for your game.
// You can override this value to use different units.
LENGTH_UNITS_PER_METER :: #config(BOX2D_LENGTH_UNITS_PER_METER, 1)

// Constants used by box2d.
// box2d uses meters-kilograms-seconds (MKS) units. Angles are always in radians unless
// degrees are indicated.
// Some values can be overridden with a define and some values can be modified at runtime.
// Other values cannot be modified without causing stability and/or performance problems.

// box2d bases all length units on meters, but you may need different units for your game.
// You can adjust this value to use different units, normally at application startup.
// @(export, link_name="b2_lengthUnitsPerMeter")
// length_units_per_meter: f32 = LENGTH_UNITS_PER_METER

PI :: 3.14159265359

// This is used to fatten AABBs in the dynamic tree. This allows proxies
// to move by a small amount without triggering a tree adjustment.
// This is in meters.
// @warning modifying this can have a significant impact on performance
AABB_MARGIN :: 0.1 * LENGTH_UNITS_PER_METER

// A small length used as a collision and constraint tolerance. Usually it is
// chosen to be numerically significant, but visually insignificant. In meters.
// @warning modifying this can have a significant impact on stability
LINEAR_SLOP :: 0.005 * LENGTH_UNITS_PER_METER

// A small angle used as a collision and constraint tolerance. Usually it is
// chosen to be numerically significant, but visually insignificant.
// @warning modifying this can have a significant impact on stability
ANGULAR_SLOP :: 2 / 180 * PI

// The maximum number of vertices on a convex polygon. You cannot increase
// this too much because b2BlockAllocator has a maximum object size.
// You may define this externally.
MAX_POLYGON_VERTICES :: #config(BOX2D_MAX_POLYGON_VERTICES, 8)

// Maximum number of simultaneous worlds that can be allocated
// You may define this externally.
MAX_WORLDS :: #config(BOX2D_MAX_WORLDS, 32)

// The maximum linear translation of a body per step. This limit is very large and is used
// to prevent numerical problems. You shouldn't need to adjust this. Meters.
// @warning modifying this can have a significant impact on stability
MAX_TRANSLATION :: 4.0 * LENGTH_UNITS_PER_METER
MAX_TRANSLATION_SQUARED :: MAX_TRANSLATION * MAX_TRANSLATION

// The maximum angular velocity of a body. This limit is very large and is used
// to prevent numerical problems. You shouldn't need to adjust this.
// @warning modifying this can have a significant impact on stability
MAX_ROTATION :: 0.5 * PI
MAX_ROTATION_SQUARED :: MAX_ROTATION * MAX_ROTATION

// TODO_ERIN make dynamic based on speed?
// @warning modifying this can have a significant impact on stability
SPECULATIVE_DISTANCE :: 4.0 * LINEAR_SLOP

// The time that a body must be still before it will go to sleep. In seconds.
TIME_TO_SLEEP :: #config(BOX2D_TIME_TO_SLEEP, 0.5)

// A body cannot sleep if its linear velocity is above this tolerance.
LINEAR_SLEEP_TOLERANCE :: #config(BOX2D_LINEAR_SLEEP_TOLERANCE, 0.01 * LENGTH_UNITS_PER_METER)

// A body cannot sleep if its angular velocity is above this tolerance.
ANGULAR_SLEEP_TOLERANCE :: #config(BOX2D_ANGULAR_SLEEP_TOLERANCE, 2 / 180 * PI)

// Used to detect bad values. Positions greater than about 16km will have precision
// problems, so 100km as a limit should be fine in all cases.
HUGE :: 100_000.0 * LENGTH_UNITS_PER_METER

// Maximum parallel workers. Used to size some static arrays.
MAX_WORKERS :: 64

// Solver graph coloring
GRAPH_COLORS_COUNT :: 12

Version :: struct
{
	// significant changes
	major,

	// incremental changes
	minor,

	// bug fixes
	revision: i32,
}