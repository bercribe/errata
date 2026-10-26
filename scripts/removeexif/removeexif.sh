# removeexif - remove EXIF data from JPEGs
exec jhead -purejpg "$@"
