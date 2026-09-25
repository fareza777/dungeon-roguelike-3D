import json, sys
# args: prev_name, name, arm_n, stats_json(list of lines), opt_text, flv_text
prev, name, armn, stats, optt, flvt = sys.argv[1], sys.argv[2], int(sys.argv[3]), json.loads(sys.argv[4]), sys.argv[5], sys.argv[6]
P = '/home/ubuntu/repos/dungeon-roguelike-3D/game/main.gd'
m = open(P).read()
OPT = '\t\t{"text": "' + prev
ARM = '\t\t%d:\n\t\t\tnemesis_bounty = true\n\t\t\toname = "BLOOD DEBT"' % armn
FLV = '\t"' + prev + '":'
i = m.index(OPT)
j = m.index('\n\t]', i)
assert m[i:j].count('\n') == 0, "tail:%d" % m[i:j].count('\n')
NEWOPT = '\t\t{"text": "' + name + ' — ' + optt + '"},\n'
assert m.count(ARM) == 1, "arm:%d" % m.count(ARM)
NEWARM = '\t\t%d:\n' % armn + ''.join('\t\t\t%s\n' % s for s in stats) + '\t\t\toname = "%s"\n' % name + '\t\t%d:\n\t\t\tnemesis_bounty = true\n\t\t\toname = "BLOOD DEBT"' % (armn + 1)
i = m.index(FLV)
j = m.index('\n', i)
assert m[i:j].endswith('",'), "flvend:%r" % m[i:j]
NEWFLV = '\n\t"' + name + '": "' + flvt + '",'
m = m[:j] + NEWFLV + m[j:]
m = m.replace(ARM, NEWARM, 1)
i = m.index(OPT)
j = m.index('\n\t]', i)
m = m[:j + 1] + NEWOPT + m[j + 1:]
open(P, 'w').write(m)
print("ok")
