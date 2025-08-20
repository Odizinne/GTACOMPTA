#include <QCoreApplication>
#include <QCommandLineParser>
#include <QDebug>
#include <QTextStream>
#include <QDir>
#include <QLoggingCategory>
#include <QStandardPaths>
#include "databaseserver.h"

void printWelcomeBanner()
{
    QTextStream out(stdout);
    out << Qt::endl;
    out << "========================================" << Qt::endl;
    out << "    GTACOMPTA Database Server v1.0     " << Qt::endl;
    out << "========================================" << Qt::endl;
    out << "Remote storage server for GTACOMPTA" << Qt::endl;
    out << "Built with Qt " << QT_VERSION_STR << Qt::endl;
    out << Qt::endl;
}

void printServerInfo(quint16 port, const QString &password, const QString &dataDir)
{
    QTextStream out(stdout);
    out << "Server Configuration:" << Qt::endl;
    out << "  Port: " << port << Qt::endl;
    out << "  Password: " << (password.isEmpty() ? "none (WARNING: No authentication!)" : "***protected***") << Qt::endl;
    out << "  Data Directory: " << dataDir << Qt::endl;
    out << Qt::endl;
    out << "API Endpoints:" << Qt::endl;
    out << "  GET  /api/test              - Test connection" << Qt::endl;
    out << "  GET  /api/status            - Server status" << Qt::endl;
    out << "  GET  /api/load/<collection> - Load data" << Qt::endl;
    out << "  POST /api/save/<collection> - Save data" << Qt::endl;
    out << Qt::endl;
    out << "CORS: Enabled for all origins" << Qt::endl;
    out << "Authentication: X-Password header required" << Qt::endl;
    out << Qt::endl;
    out << "Server is running... Press Ctrl+C to stop" << Qt::endl;
    out << Qt::endl;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    // Set application properties BEFORE using QStandardPaths
    app.setApplicationName("GTACOMPTAServer");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("Odizinne");

    printWelcomeBanner();

    // Setup command line parser
    QCommandLineParser parser;
    parser.setApplicationDescription("GTACOMPTA Database Server - Remote storage for GTACOMPTA applications");
    parser.addHelpOption();
    parser.addVersionOption();

    // Get default data directory using proper app settings
    QString defaultDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    // Command line options
    QCommandLineOption portOption(QStringList() << "p" << "port",
                                  "Port to listen on (default: 3000)",
                                  "port", "3000");
    QCommandLineOption passwordOption(QStringList() << "w" << "password",
                                      "Authentication password (default: 1234)",
                                      "password", "1234");
    QCommandLineOption dataOption(QStringList() << "d" << "data-dir",
                                  QString("Data directory path (default: %1)").arg(defaultDataDir),
                                  "path");
    QCommandLineOption verboseOption(QStringList() << "v" << "verbose",
                                     "Enable verbose logging");

    parser.addOption(portOption);
    parser.addOption(passwordOption);
    parser.addOption(dataOption);
    parser.addOption(verboseOption);

    // Parse command line
    parser.process(app);

    // Create and configure server
    DatabaseServer server;

    // Set password
    QString password = parser.value(passwordOption);
    if (password.isEmpty()) {
        qWarning() << "WARNING: No password set! Server will be unprotected.";
    }
    server.setPassword(password);

    // Determine data directory
    QString dataDir;
    if (parser.isSet(dataOption)) {
        // Custom data directory provided
        dataDir = parser.value(dataOption);
    } else {
        // Use default AppDataLocation
        dataDir = defaultDataDir;
    }

    // Ensure data directory exists
    QDir dir(dataDir);
    if (!dir.exists() && !dir.mkpath(dataDir)) {
        qCritical() << "Failed to create data directory:" << dataDir;
        return 1;
    }

    server.setDataDirectory(dataDir);

    // Parse and validate port
    bool portOk;
    quint16 port = parser.value(portOption).toUShort(&portOk);
    if (!portOk || port == 0) {
        qCritical() << "Invalid port number:" << parser.value(portOption);
        return 1;
    }

    // Enable verbose logging if requested
    if (parser.isSet(verboseOption)) {
        QLoggingCategory::setFilterRules("*.debug=true");
        qDebug() << "Verbose logging enabled";
    }

    // Start server
    if (!server.start(port)) {
        qCritical() << "Failed to start server on port" << port;
        return 1;
    }

    // Print server information
    printServerInfo(port, password, dataDir);

    // Handle graceful shutdown
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&server]() {
        qDebug() << "Shutting down server...";
        server.stop();
    });

    // Run the application
    int result = app.exec();

    qDebug() << "Server shutdown complete";
    return result;
}
