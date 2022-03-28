
meter = 0
meterRatio = 80
forceMultiplier = 300

char0 = string.byte("0")
char9 = string.byte("9")

enet = require "enet"

buttonSize = Vector(0.1, 0.075)

buttonColors = {
  [false] = { 0.302, 0.847, 0.922, 1 },
  [true] = { 0.035, 0.122, 0.259, 1 }
}

textFieldColors = {
  [false] = { 1, 1, 1, 1 },
  [true] = { 0.302, 0.847, 0.922, 1 }
}


damping = 1

pi = math.pi

STATE_IDLE = 0
-- hitting cue ball
STATE_HITTING = 1
-- placing cue ball after foul
STATE_PLACING = 2


GROUP_STRIPES = 0
GROUP_NONE = 1
GROUP_SOLIDS = 2

-- any ball hit a rail "контакт с бортиком"
EVENT_RAIL_HIT = 0
-- the cue ball hit the corresponding group's ball "контакт с группой"
EVENT_CUE_HIT = 1
-- a striped or solid ball was pocketed "падение шара"
EVENT_POCKET = 2
-- the cue ball was pocketed "падение битка"
EVENT_CUE_POCKET = 3
-- the 8-ball was pocketed "падение шара №8"
EVENT_FINAL_POCKET = 4
-- cue ball hit 8 ball "контакт с шаром №8"
EVENT_FINAL_HIT = 5
-- cue ball hit any ball "контакт с шаром"
EVENT_GENERAL_HIT = 6

MESSAGE_CUE_HIT = 0
MESSAGE_CUE_PLACE = 1
MESSAGE_POS = 2
MESSAGE_LOSS = 3
MESSAGE_VICTORY = 4
MESSAGE_FOUL = 5
MESSAGE_BREAK_SHOT = 6
MESSAGE_LEGAL_SHOT = 7
MESSAGE_GROUPS = 8
