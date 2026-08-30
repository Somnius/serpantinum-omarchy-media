const assert = require("node:assert/strict")
const model = require("../Model.js")

assert.equal(model.clamp(-1, 0, 1), 0)
assert.equal(model.clamp(2, 0, 1), 1)
assert.equal(model.clamp("bad", 0, 1), 0)
assert.equal(model.volumePercent(0.426), 43)
assert.equal(model.volumeIcon(0.8, false, true), "")
assert.equal(model.volumeIcon(0.8, true, true), "")

const stopped = { dbusName: "stopped", identity: "Stopped", canPlay: true }
const playing = { dbusName: "playing", identity: "Playing", isPlaying: true }
assert.equal(model.selectPlayer([stopped, playing], null), playing)
assert.equal(model.selectPlayer([stopped, playing], "stopped"), stopped)
assert.equal(model.selectPlayer([], null), null)
assert.equal(model.title(null), "Nothing playing")
assert.equal(model.subtitle(null), "Start a media player to see controls")

console.log("Model tests passed")
