extends Node

enum TEAM_COLOR_ENUM {
	NONE,
	BLUE,
	RED,
}

var team_color_object = {
	TEAM_COLOR_ENUM.NONE: Color(1, 1, 1, 1),
	TEAM_COLOR_ENUM.BLUE: Color(0.2, 0.66, 0.87, 1),
	TEAM_COLOR_ENUM.RED: Color(0.66, 0.35, 0.45, 1),
}
