# markdownquote - add > before every line
import sys

for line in sys.stdin:
    trimmed = line.strip()
    if trimmed == "":
        print(">")
    elif trimmed.startswith(">"):
        print(trimmed)
    else:
        print("> " + trimmed)
