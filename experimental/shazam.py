from ShazamAPI import Shazam
import json

audioFile = open('test/sample.opus', 'rb').read()
shazam = Shazam(audioFile)
recognize = shazam.recognizeSong()
print(json.dumps(next(recognize), sort_keys=True, indent=2))
