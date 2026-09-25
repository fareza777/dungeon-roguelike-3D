import json, sys
# args: prev_opt_tail, name, arm_n, stats_json, opt_flavor, toast_flavor
prev, name, armn, stats, optf, tf = sys.argv[1], sys.argv[2], int(sys.argv[3]), json.loads(sys.argv[4]), sys.argv[5], sys.argv[6]
P = '/home/ubuntu/repos/dungeon-roguelike-3D/game/main.gd'
m = open(P).read()
OPT = '\t\t{"text": "' + prev + '"},\n\t]\n\tbless_pick.clear()'
assert m.count(OPT) == 1, "opt:%d" % m.count(OPT)
ARM = '\t\t50:\n\t\t\tStats.buff_aspd += 0.15\n\t\t\tStats.buff_speed_pct -= 0.05\n\t\t\ttoast("Gunnel Grip: white-knuckled on the rail — +15% attack speed, −5% speed this run")'
assert m.count(ARM) == 1, "arm:%d" % m.count(ARM)
NEWOPT = '\t\t{"text": "' + prev + '"},\n\t\t{"text": "' + name + ' — ' + optf + '"},\n\t]\n\tbless_pick.clear()'
NEWARM = '\t\t%d:\n' % armn + ''.join('\t\t\t%s\n' % s for s in stats) + '\t\t\ttoast("%s: %s")\n' % (name, tf) + ARM
m = m.replace(OPT, NEWOPT, 1)
m = m.replace(ARM, NEWARM, 1)
open(P, 'w').write(m)
print("ok")
