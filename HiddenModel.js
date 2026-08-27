function hideSideNormalized(value) {
  return String(value || "before").toLowerCase() === "after" ? "after" : "before"
}

function autoHideSeconds(value) {
  var n = Math.round(Number(value))
  var allowed = [5, 10, 15, 30, 60]
  for (var i = 0; i < allowed.length; i++) {
    if (allowed[i] === n) return n
  }
  return 10
}

function hideableIds(bar, moduleName, region, hideSide) {
  if (!bar || typeof bar.layoutEntries !== "function") return []
  var entries = bar.layoutEntries(region)
  var slice = hideSideNormalized(hideSide) === "after"
    ? bar.entriesAfter(entries, moduleName)
    : bar.entriesBefore(entries, moduleName)
  var ids = []
  var seen = {}
  for (var i = 0; i < slice.length; i++) {
    var id = bar.entryId(slice[i])
    if (!id || id === moduleName || seen[id]) continue
    seen[id] = true
    ids.push(id)
  }
  return ids
}

if (typeof module !== "undefined") {
  module.exports = {
    hideSideNormalized: hideSideNormalized,
    autoHideSeconds: autoHideSeconds,
    hideableIds: hideableIds
  }
}
