tmpdir=$(mktemp -d /tmp/epub-cleanup-XXXXXX)
mobiname="$tmpdir/file.mobi"
epubname="$tmpdir/file.epub"

ebook-convert "$1" "$mobiname"
ebook-convert "$mobiname" "$epubname"
mv "$epubname" "$1"
