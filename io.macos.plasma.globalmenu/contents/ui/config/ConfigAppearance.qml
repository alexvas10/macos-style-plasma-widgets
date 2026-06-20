import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_boldAppName:    boldAppNameCheck.checked
    property alias cfg_fontSize:       fontSizeSpin.value
    property alias cfg_menuSpacing:    menuSpacingSpin.value
    property alias cfg_filterByScreen: filterByScreenCheck.checked
    property alias cfg_fadeOnNoMenu:   fadeOnNoMenuCheck.checked

    Kirigami.FormLayout {
        anchors.left:  parent.left
        anchors.right: parent.right

        QQC2.CheckBox {
            id:               boldAppNameCheck
            Kirigami.FormData.label: i18n("Style:")
            text:             i18n("Bold application name")
        }

        QQC2.CheckBox {
            id:               fadeOnNoMenuCheck
            text:             i18n("Show Finder bar when no window is active")
        }

        QQC2.CheckBox {
            id:               filterByScreenCheck
            text:             i18n("Show only tasks from current screen")
        }

        QQC2.SpinBox {
            id:               fontSizeSpin
            Kirigami.FormData.label: i18n("Font size:")
            from:             0
            to:               32
            // 0 means inherit from panel
            textFromValue: function(value) {
                return value === 0 ? i18n("Inherit from panel") : value + "pt"
            }
        }

        QQC2.SpinBox {
            id:               menuSpacingSpin
            Kirigami.FormData.label: i18n("Menu item spacing:")
            from:             0
            to:               24
            suffix:           " px"
        }
    }
}
