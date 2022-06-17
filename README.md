# kateri
antigenic map viewer and pdf generator

# dependencies

macos M1: (https://dev.to/staceypyee/installing-cocoapods-on-m1-macbook-air-big-sur-h0l)
  brew install cocoapods

# socket communication

Server program can send the data to kateri through socket, data starts
with 4 byte code, followed by 4 bytes payload size, followed by
payload, followed by padding to make sure the whole chunk ends at 4 byte boundary.

Supported codes:

- CHRT. Playload is uncompressed chart data in ace format (json)

- COMD. Playload is json with the command and arguments. Supported commands:

  {"C": "set_style", "style": "<style name>"}
  {"C": "pdf", "width": 800} - send pdf data back to the other socket end
