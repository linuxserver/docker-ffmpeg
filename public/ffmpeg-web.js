

// Ace editor
var editor = ace.edit("editor");
editor.setTheme("ace/theme/chrome");
editor.session.setMode("ace/mode/sh");
editor.$blockScrolling = Infinity;
editor.setOptions({
  readOnly: false,
});
editor.setValue('ffmpeg -y \\\n -vaapi_device /dev/dri/renderD129 \\\n -i ${INFILE} \\\n -b:v 4000k \\\n -c:v h264 \\\n ${OUTFILE}',-1);