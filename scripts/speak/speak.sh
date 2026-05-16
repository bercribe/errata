# speak - text-to-speech from stdin (strips markdown)
if hash say 2>/dev/null; then
  pandoc -f commonmark -t plain --wrap=preserve | say
elif hash espeak-ng 2>/dev/null; then
  pandoc -f commonmark -t plain --wrap=preserve | espeak-ng
else
  echo "couldn't find any TTS program" >&2
  exit 1
fi
