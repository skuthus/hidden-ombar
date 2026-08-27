import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "HiddenModel.js" as HiddenModel

// Chevron that conceals neighboring bar widgets until expanded.
// Place it after the widgets you want to tuck away, then click to peek.
BarWidget {
  id: root
  moduleName: "skuthus.hidden-om-bar"

  property bool expanded: true
  property bool prefsOpen: false
  property var concealedSlots: []

  readonly property bool autoHide: setting("autoHide", true) !== false
  readonly property int autoHideSeconds: HiddenModel.autoHideSeconds(setting("autoHideSeconds", 10))
  readonly property bool hoverToExpand: setting("hoverToExpand", false) === true
  readonly property string hideSide: HiddenModel.hideSideNormalized(setting("hideSide", "before"))
  readonly property bool hideBefore: hideSide === "before"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string chevronText: {
    if (hideBefore) return expanded ? "\uf054" : "\uf053"
    return expanded ? "\uf053" : "\uf054"
  }
  readonly property string tooltipText: expanded ? "Hide widgets" : "Show hidden widgets"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleExpanded() {
    if (expanded) collapse()
    else expand()
  }

  function expand() {
    expanded = true
    revealConcealed()
    bumpAutoHide()
  }

  function collapse() {
    prefsOpen = false
    expanded = false
    applyConceal()
    autoHideTimer.stop()
  }

  function close() {
    prefsOpen = false
  }

  function hostSlot() {
    if (!bar || !bar.moduleSlots) return null
    var slots = bar.moduleSlots
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] && slots[i].activeItem === root) return slots[i]
    }
    return null
  }

  function hideableSlots() {
    var host = hostSlot()
    if (!host || !bar) return []
    var names = HiddenModel.hideableIds(bar, host.moduleName || root.moduleName, host.region, hideSide)
    var wanted = {}
    for (var n = 0; n < names.length; n++) wanted[names[n]] = true
    var window = typeof bar.slotWindow === "function" ? bar.slotWindow(host) : null
    var result = []
    var slots = bar.moduleSlots
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i]
      if (!slot || slot === host) continue
      if (slot.region !== host.region) continue
      if (!wanted[slot.moduleName]) continue
      if (window && typeof bar.sameWindow === "function" && !bar.sameWindow(bar.slotWindow(slot), window))
        continue
      result.push(slot)
    }
    return result
  }

  function revealConcealed() {
    var slots = concealedSlots
    for (var i = 0; i < slots.length; i++) {
      if (slots[i]) slots[i].visible = true
    }
    concealedSlots = []
  }

  function applyConceal() {
    if (expanded) {
      revealConcealed()
      return
    }
    var wanted = concealableNow()
    var previous = concealedSlots
    for (var p = 0; p < previous.length; p++) {
      if (previous[p] && wanted.indexOf(previous[p]) === -1)
        previous[p].visible = true
    }
    for (var i = 0; i < wanted.length; i++) wanted[i].visible = false
    concealedSlots = wanted
  }

  function concealableNow() {
    var slots = hideableSlots()
    var result = []
    var previous = concealedSlots
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i]
      if (!slot) continue
      if (slot.visible || previous.indexOf(slot) !== -1) result.push(slot)
    }
    return result
  }

  function scheduleApply() {
    applyTimer.restart()
  }

  function bumpAutoHide() {
    autoHideTimer.stop()
    if (!expanded || !autoHide) return
    autoHideTimer.interval = autoHideSeconds * 1000
    autoHideTimer.start()
  }

  function shouldDeferCollapse() {
    if (prefsOpen) return true
    if (hover.hovered) return true
    if (bar && bar.barHovered) return true
    if (bar && bar.barDragSource) return true
    if (bar && bar.activePopout) return true
    return false
  }

  function persist(patch) {
    var entry = { id: root.moduleName }
    var current = root.settings || {}
    for (var key in current) {
      if (key !== "id") entry[key] = current[key]
    }
    for (var next in patch) entry[next] = patch[next]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setAutoHide(value) {
    persist({ autoHide: value === true })
    if (value) bumpAutoHide()
    else autoHideTimer.stop()
  }

  function setAutoHideSeconds(value) {
    persist({ autoHideSeconds: HiddenModel.autoHideSeconds(value) })
    bumpAutoHide()
  }

  function setHoverToExpand(value) {
    persist({ hoverToExpand: value === true })
  }

  function setHideBefore(value) {
    persist({ hideSide: value ? "before" : "after" })
    scheduleApply()
  }

  onExpandedChanged: {
    if (expanded) bumpAutoHide()
    else autoHideTimer.stop()
    scheduleApply()
  }

  onBarChanged: scheduleApply()
  onHideSideChanged: scheduleApply()
  Component.onCompleted: {
    scheduleApply()
    startupCollapse.start()
  }
  Component.onDestruction: revealConcealed()

  Connections {
    target: root.bar
    function onBarConfigSerialChanged() { root.scheduleApply() }
    function onModuleSlotsChanged() { root.scheduleApply() }
    function onBarHoveredChanged() {
      if (root.bar && root.bar.barHovered) root.bumpAutoHide()
    }
    function onBarDragSourceChanged() {
      if (root.bar && root.bar.barDragSource) root.expand()
      else root.bumpAutoHide()
    }
  }

  Timer {
    id: applyTimer
    interval: 1
    onTriggered: root.applyConceal()
  }

  Timer {
    id: startupCollapse
    interval: 1000
    repeat: false
    onTriggered: root.collapse()
  }

  Timer {
    id: autoHideTimer
    repeat: false
    onTriggered: {
      if (root.shouldDeferCollapse()) root.bumpAutoHide()
      else root.collapse()
    }
  }

  Timer {
    id: hoverDwell
    interval: 500
    repeat: false
    onTriggered: {
      if (root.hoverToExpand && !root.expanded && hover.hovered) root.expand()
    }
  }

  IpcHandler {
    target: "skuthus.hidden-om-bar"

    function toggle(): void {
      root.broadcast("toggleExpanded")
    }

    function expand(): void {
      root.broadcast("expand")
    }

    function collapse(): void {
      root.broadcast("collapse")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.chevronText
    textRotation: root.vertical ? 90 : 0
    tooltipText: root.tooltipText
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        root.prefsOpen = !root.prefsOpen
        return
      }
      if (mouseButton === Qt.MiddleButton) {
        root.setAutoHide(!root.autoHide)
        return
      }
      root.toggleExpanded()
    }
  }

  HoverHandler {
    id: hover
    onHoveredChanged: {
      if (hovered) {
        root.bumpAutoHide()
        if (root.hoverToExpand && !root.expanded) hoverDwell.restart()
      } else {
        hoverDwell.stop()
      }
    }
  }

  PopupCard {
    id: prefsPopup
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.prefsOpen
    contentWidth: prefsPopup.fittedContentWidth(Style.space(300))
    contentHeight: prefsPopup.fittedContentHeight(prefsColumn.implicitHeight)

    Column {
      id: prefsColumn
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        text: "Hidden Om-Bar"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        width: parent.width
        text: "Widgets on the hidden side of this chevron collapse until you click. Drag the chevron to choose what stays visible."
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Toggle {
        width: parent.width
        label: "Auto collapse"
        description: "Hide the widgets again after the delay below."
        checked: root.autoHide
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.setAutoHide(!root.autoHide)
      }

      Text {
        visible: root.autoHide
        text: "Collapse after"
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Row {
        visible: root.autoHide
        spacing: Style.space(6)
        Repeater {
          model: [5, 10, 15, 30, 60]
          Button {
            required property int modelData
            text: modelData === 60 ? "60s" : modelData + "s"
            selected: root.autoHideSeconds === modelData
            foreground: root.foreground
            fontFamily: root.fontFamily
            horizontalPadding: 8
            verticalPadding: 3
            fontSize: Style.font.bodySmall
            onClicked: root.setAutoHideSeconds(modelData)
          }
        }
      }

      Toggle {
        width: parent.width
        label: "Hover to expand"
        description: "Hold the pointer on the chevron to peek without clicking."
        checked: root.hoverToExpand
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.setHoverToExpand(!root.hoverToExpand)
      }

      Toggle {
        width: parent.width
        label: "Hide widgets before this icon"
        description: "Turn off to hide the widgets after this icon instead."
        checked: root.hideBefore
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.setHideBefore(!root.hideBefore)
      }
    }
  }
}
