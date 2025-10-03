#include <QCoreApplication>
#include <QCommandLineParser>
#include <QDebug>
#include <QTextStream>
#include <QDir>
#include <QLoggingCategory>
#include <QStandardPaths>
#include "databaseserver.h"
#include "usermanager.h"

void printWelcomeBanner()
{
    QTextStream out(stdout);
    out << Qt::endl;
    out << "========================================" << Qt::endl;
    out << "    GTACOMPTA Database Server v1.5.1    " << Qt::endl;
    out << "========================================" << Qt::endl;
    out << "Remote storage server for GTACOMPTA" << Qt::endl;
    out << "Built with Qt " << QT_VERSION_STR << Qt::endl;
    out << Qt::endl;
}

void printServerInfo(quint16 port, const QString &dataDir)
{
    QTextStream out(stdout);
    out << "Server Configuration:" << Qt::endl;
    out << "  Port: " << port << Qt::endl;
    out << "  Data Directory: " << dataDir << Qt::endl;
    out << Qt::endl;
    out << "API Endpoints:" << Qt::endl;
    out << "  GET  /api/test              - Test connection" << Qt::endl;
    out << "  GET  /api/status            - Server status" << Qt::endl;
    out << "  GET  /api/load/<collection> - Load data" << Qt::endl;
    out << "  POST /api/save/<collection> - Save data" << Qt::endl;
    out << Qt::endl;
    out << "CORS: Handled by nginx reverse proxy" << Qt::endl;
    out << "Authentication: Username/Password (X-Username, X-User-Password headers)" << Qt::endl;
    out << "SSL: Handled by nginx reverse proxy" << Qt::endl;
    out << Qt::endl;
    out << "Server is running... Press Ctrl+C to stop" << Qt::endl;
    out << Qt::endl;
}

void printUsage()
{
    QTextStream out(stdout);
    out << Qt::endl;
    out << "User Management Examples:" << Qt::endl;
    out << "  --add-user username password         - Add user with full access" << Qt::endl;
    out << "  --add-user username password --readonly - Add read-only user" << Qt::endl;
    out << "  --delete-user username               - Delete user" << Qt::endl;
    out << "  --list-users                         - List all users" << Qt::endl;
    out << Qt::endl;
    out << "Note: Username and password should not contain spaces" << Qt::endl;
    out << Qt::endl;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    app.setApplicationName("GTACOMPTAServer");
    app.setApplicationVersion("1.5.1");
    app.setOrganizationName("Odizinne");

    printWelcomeBanner();

    QCommandLineParser parser;
    parser.setApplicationDescription("GTACOMPTA Database Server - Remote storage for GTACOMPTA applications");
    parser.addHelpOption();
    parser.addVersionOption();

    QString defaultDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    QCommandLineOption portOption(QStringList() << "p" << "port",
                                  "Port to listen on (default: 3000)",
                                  "port", "3000");
    QCommandLineOption dataOption(QStringList() << "d" << "data-dir",
                                  QString("Data directory path (default: %1)").arg(defaultDataDir),
                                  "path");
    QCommandLineOption verboseOption(QStringList() << "verbose",
                                     "Enable verbose logging");

    // User management options - simplified approach
    QCommandLineOption addUserOption(QStringList() << "add-user",
                                     "Add a new user. Requires 2 positional arguments after this flag: username password");
    QCommandLineOption deleteUserOption(QStringList() << "delete-user",
                                        "Delete a user. Requires 1 positional argument: username",
                                        "username");
    QCommandLineOption readonlyOption(QStringList() << "readonly",
                                      "Make the new user read-only (use with --add-user)");
    QCommandLineOption listUsersOption(QStringList() << "list-users",
                                       "List all registered users");

    parser.addOption(portOption);
    parser.addOption(dataOption);
    parser.addOption(verboseOption);
    parser.addOption(addUserOption);
    parser.addOption(deleteUserOption);
    parser.addOption(readonlyOption);
    parser.addOption(listUsersOption);

    parser.process(app);

    if (parser.isSet(verboseOption)) {
        QLoggingCategory::setFilterRules("*.debug=true");
        qDebug() << "Verbose logging enabled";
    }

    // Setup data directory
    QString dataDir;
    if (parser.isSet(dataOption)) {
        dataDir = parser.value(dataOption);
    } else {
        dataDir = defaultDataDir;
    }

    QDir dir(dataDir);
    if (!dir.exists() && !dir.mkpath(dataDir)) {
        qCritical() << "Failed to create data directory:" << dataDir;
        return 1;
    }

    // Create user manager for user management operations
    UserManager userManager;
    userManager.setDataDirectory(dataDir);

    // Get positional arguments (arguments after options)
    QStringList positionalArgs = parser.positionalArguments();

    // Handle user management commands
    if (parser.isSet(addUserOption)) {
        if (positionalArgs.size() < 2) {
            qCritical() << "Error: --add-user requires 2 arguments: username password";
            qCritical() << "Usage: --add-user username password";
            qCritical() << "Example: ./GTACOMPTAServer --add-user gorzyne shyvana0307";
            printUsage();
            return 1;
        }

        QString username = positionalArgs[0];
        QString password = positionalArgs[1];
        bool readonly = parser.isSet(readonlyOption);

        if (userManager.userExists(username)) {
            qCritical() << "Error: User" << username << "already exists";
            return 1;
        }

        if (userManager.addUser(username, password, readonly)) {
            QTextStream out(stdout);
            out << "✓ User '" << username << "' added successfully ";
            out << (readonly ? "(read-only access)" : "(full access)") << Qt::endl;
            userManager.listUsers();
        } else {
            qCritical() << "Failed to add user" << username;
            return 1;
        }
        return 0; // Exit after user management
    }

    if (parser.isSet(deleteUserOption)) {
        QString username = parser.value(deleteUserOption);

        if (!userManager.userExists(username)) {
            qCritical() << "Error: User" << username << "does not exist";
            return 1;
        }

        if (userManager.deleteUser(username)) {
            QTextStream out(stdout);
            out << "✓ User '" << username << "' deleted successfully" << Qt::endl;
            userManager.listUsers();
        } else {
            qCritical() << "Failed to delete user" << username;
            return 1;
        }
        return 0; // Exit after user management
    }

    if (parser.isSet(listUsersOption)) {
        userManager.listUsers();
        return 0; // Exit after listing users
    }

    // If we get here, we're starting the server
    DatabaseServer server;
    server.setDataDirectory(dataDir);

    bool portOk;
    quint16 port = parser.value(portOption).toUShort(&portOk);
    if (!portOk || port == 0) {
        qCritical() << "Invalid port number:" << parser.value(portOption);
        return 1;
    }

    if (!server.start(port)) {
        qCritical() << "Failed to start server on port" << port;
        return 1;
    }

    printServerInfo(port, dataDir);

    // Show current users
    userManager.listUsers();

    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&server]() {
        qDebug() << "Shutting down server...";
        server.stop();
    });

    int result = app.exec();

    qDebug() << "Server shutdown complete";
    return result;
}
