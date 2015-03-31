
for x in *; do convert -resize 20x20 "${x}" "${x%.*}.png"; done

