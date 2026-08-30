function clamp(value, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) return minimum
  return Math.max(minimum, Math.min(maximum, number))
}

function volumePercent(value) {
  return Math.round(clamp(value, 0, 1) * 100)
}

function volumeIcon(volume, muted, available) {
  if (!available || muted || volume <= 0) return ""
  if (volume < 0.34) return ""
  if (volume < 0.67) return ""
  return ""
}

function nodeProperties(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function isOutput(node) {
  return !!(node && node.isSink && !node.isStream && node.audio)
}

function outputLabel(node) {
  if (!node) return "Unknown output"
  var properties = nodeProperties(node)
  return String(node.description || properties["device.description"]
    || properties["node.description"] || node.name || "Unknown output")
}

function playerKey(player) {
  if (!player) return ""
  return String(player.dbusName || player.desktopEntry || player.identity || "")
}

function playerLabel(player) {
  if (!player) return "Unknown player"
  return String(player.identity || player.desktopEntry || playerKey(player) || "Unknown player")
}

function hasPlayerContent(player) {
  return !!(player && (player.trackTitle || player.trackArtist || player.identity
    || player.desktopEntry || player.canTogglePlaying || player.canPlay))
}

function selectPlayer(players, preferredKey) {
  var list = Array.isArray(players) ? players : []
  var fallback = null
  for (var i = 0; i < list.length; i++) {
    var player = list[i]
    if (!hasPlayerContent(player)) continue
    if (preferredKey && playerKey(player) === preferredKey) return player
    if (player.isPlaying) return player
    if (!fallback) fallback = player
  }
  return fallback
}

function title(player) {
  return player ? String(player.trackTitle || playerLabel(player)) : "Nothing playing"
}

function subtitle(player) {
  if (!player) return "Start a media player to see controls"
  var artist = String(player.trackArtist || "")
  var album = String(player.trackAlbum || "")
  return artist && album ? artist + " · " + album : artist || album || playerLabel(player)
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    volumePercent: volumePercent,
    volumeIcon: volumeIcon,
    isOutput: isOutput,
    outputLabel: outputLabel,
    playerKey: playerKey,
    playerLabel: playerLabel,
    hasPlayerContent: hasPlayerContent,
    selectPlayer: selectPlayer,
    title: title,
    subtitle: subtitle
  }
}
