import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "ramMonitor"

    StyledText {
        width: parent.width
        text: "RAM Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "RAM usage as an animated progress bar in your DankBar, updated every second."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        settingKey: "showLabel"
        label: "Show label"
        description: "Display a text label between the icon and the bar"
        defaultValue: true
    }

    StringSetting {
        settingKey: "labelText"
        label: "Label text"
        description: "The label shown next to the icon"
        placeholder: "RAM"
        defaultValue: "RAM"
    }
}
