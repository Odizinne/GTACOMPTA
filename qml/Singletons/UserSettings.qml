pragma Singleton

import QtCore

Settings {
    property bool firstRun: true
    property bool darkMode: true

    property bool useRemoteDatabase: false
    property string remoteHost: "localhost"
    property string remoteUsername: ""
    property string remoteUserPassword: ""
}
