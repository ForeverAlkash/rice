import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.services
import qs.widgets

// A sticky note: free text autosaved to ~/notes.md. External edits (any
// editor) show up live while the field is not focused. Flexible: fills
// whatever the Home tab layout gives it.
Card {
    id: root

    clip: true

    // blocks the save timer while the file content is being mirrored in
    property bool syncing: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            SectionTitle {
                Layout.fillWidth: true
                icon: "notebook"
                text: "Notes"
                accent: Theme.primary
            }
            Txt {
                text: "autosaves"
                font.pixelSize: 10
                color: Theme.alpha(Theme.fgDim, 0.7)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextEdit {
                id: area
                anchors.fill: parent
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                color: Theme.fg
                selectionColor: Theme.alpha(Theme.primary, 0.35)
                selectedTextColor: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                cursorDelegate: Rectangle {
                    width: 2
                    radius: 1
                    color: Theme.primary
                }

                onTextChanged: if (!root.syncing)
                    saveTimer.restart()
            }

            // TextEdit has no placeholder — a dim hint when empty
            Txt {
                anchors.top: parent.top
                anchors.left: parent.left
                visible: area.text === "" && !area.activeFocus
                text: "Write anything — saved to ~/notes.md"
                font.pixelSize: 12
                color: Theme.alpha(Theme.fgDim, 0.55)
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 900
        onTriggered: noteFile.setText(area.text)
    }

    FileView {
        id: noteFile
        path: Config.home + "/notes.md"
        watchChanges: true
        onLoaded: {
            const t = noteFile.text();
            if (t !== area.text && !area.activeFocus) {
                root.syncing = true;
                area.text = t;
                root.syncing = false;
            }
        }
        onFileChanged: reloadTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                noteFile.setText("");
        }
    }

    Timer {
        id: reloadTimer
        interval: 250
        onTriggered: noteFile.reload()
    }
}
