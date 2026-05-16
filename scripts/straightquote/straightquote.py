# straightquote - convert smart quotes to straight quotes
import sys

for line in sys.stdin:
    line = line.replace("\u201c", '"').replace("\u201d", '"')
    line = line.replace("\u2018", "'").replace("\u2019", "'")
    sys.stdout.write(line)
