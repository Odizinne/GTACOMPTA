// src/databaseserver.cpp
#include "databaseserver.h"
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QHostAddress>
#include <QTextStream>

DatabaseServer::DatabaseServer(QObject *parent)
    : QObject(parent)
    , m_server(new QTcpServer(this))
    , m_password("1234")  // Updated default password
{
    // The data directory will be set by main.cpp using proper app settings
    // We just initialize with empty string here
    m_dataDirectory = "";

    connect(m_server, &QTcpServer::newConnection, this, &DatabaseServer::newConnection);

    // Setup logging timer
    m_logTimer = new QTimer(this);
    connect(m_logTimer, &QTimer::timeout, this, [this]() {
        qDebug() << "[" << QDateTime::currentDateTime().toString() << "] Server running...";
    });
}

DatabaseServer::~DatabaseServer()
{
    stop();
}

bool DatabaseServer::start(quint16 port)
{
    if (m_server->listen(QHostAddress::Any, port)) {
        qDebug() << "GTACOMPTA Database Server started on port" << port;
        qDebug() << "Data directory:" << m_dataDirectory;
        qDebug() << "Password protection enabled";

        m_logTimer->start(30000); // Log every 30 seconds
        return true;
    }

    qWarning() << "Failed to start server on port" << port << ":" << m_server->errorString();
    return false;
}

void DatabaseServer::stop()
{
    if (m_server->isListening()) {
        m_server->close();
        m_logTimer->stop();
        qDebug() << "Server stopped";
    }
}

void DatabaseServer::setPassword(const QString &password)
{
    m_password = password;
    qDebug() << "Password updated";
}

void DatabaseServer::setDataDirectory(const QString &path)
{
    m_dataDirectory = path;
    QDir().mkpath(m_dataDirectory);
    qDebug() << "Data directory set to:" << m_dataDirectory;
}

void DatabaseServer::newConnection()
{
    while (m_server->hasPendingConnections()) {
        QTcpSocket *socket = m_server->nextPendingConnection();
        connect(socket, &QTcpSocket::readyRead, this, &DatabaseServer::readyRead);
        connect(socket, &QTcpSocket::disconnected, this, &DatabaseServer::clientDisconnected);
    }
}

void DatabaseServer::readyRead()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket) return;

    QByteArray data = socket->readAll();
    QString request = QString::fromUtf8(data);

    handleHttpRequest(socket, request);
}

void DatabaseServer::clientDisconnected()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket*>(sender());
    if (socket) {
        socket->deleteLater();
    }
}

void DatabaseServer::handleHttpRequest(QTcpSocket *socket, const QString &request)
{
    QString method = parseHttpMethod(request);
    QString path = parseHttpPath(request);
    QString body = parseHttpBody(request);
    QString authHeader = getHttpHeader(request, "X-Password");

    QString response;

    // CORS preflight
    if (method == "OPTIONS") {
        response = createHttpResponse(200, "", "text/plain");
        response.replace("Content-Type: text/plain",
                         "Content-Type: text/plain\r\n"
                         "Access-Control-Allow-Origin: *\r\n"
                         "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n"
                         "Access-Control-Allow-Headers: Content-Type, X-Password");
        socket->write(response.toUtf8());
        socket->close();
        return;
    }

    // Authentication check
    if (!authenticate(authHeader)) {
        QJsonObject error;
        error["error"] = "Unauthorized";
        response = createHttpResponse(401, QJsonDocument(error).toJson());
        logRequest(method, path, "UNAUTHORIZED");
    }
    // Test connection
    else if (method == "GET" && path == "/api/test") {
        QJsonObject result;
        result["success"] = true;
        result["message"] = "Connection successful";
        result["server"] = "GTACOMPTA Server v1.0";
        result["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

        response = createHttpResponse(200, QJsonDocument(result).toJson());
        logRequest(method, path, "Connection test successful");
    }
    // Save data
    else if (method == "POST" && path.startsWith("/api/save/")) {
        QString collection = path.mid(10); // Remove "/api/save/"

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(body.toUtf8(), &error);

        if (error.error != QJsonParseError::NoError) {
            QJsonObject errorObj;
            errorObj["error"] = "Invalid JSON";
            response = createHttpResponse(400, QJsonDocument(errorObj).toJson());
        } else {
            QJsonObject requestData = doc.object();
            QJsonArray data = requestData["data"].toArray();

            bool success = saveCollection(collection, data);

            QJsonObject result;
            result["success"] = success;
            if (!success) {
                result["error"] = "Failed to save data";
            }

            response = createHttpResponse(200, QJsonDocument(result).toJson());
            logRequest(method, path, QString("Save %1: %2").arg(collection).arg(success ? "SUCCESS" : "FAILED"));
        }
    }
    // Load data
    else if (method == "GET" && path.startsWith("/api/load/")) {
        QString collection = path.mid(10); // Remove "/api/load/"

        QJsonObject data = loadCollection(collection);
        response = createHttpResponse(200, QJsonDocument(data).toJson());
        logRequest(method, path, QString("Load %1: %2 items").arg(collection).arg(data["data"].toArray().size()));
    }
    // Server status
    else if (method == "GET" && path == "/api/status") {
        QJsonObject status;
        status["server"] = "GTACOMPTA Database Server";
        status["version"] = "1.0.0";
        status["uptime"] = QDateTime::currentDateTime().toString(Qt::ISODate);
        status["dataDirectory"] = m_dataDirectory;

        // Count collections
        QDir dataDir(m_dataDirectory);
        QStringList jsonFiles = dataDir.entryList(QStringList() << "*.json", QDir::Files);
        status["collections"] = jsonFiles.size();

        response = createHttpResponse(200, QJsonDocument(status).toJson());
        logRequest(method, path, "Status check");
    }
    // Not found
    else {
        QJsonObject error;
        error["error"] = "Not found";
        response = createHttpResponse(404, QJsonDocument(error).toJson());
        logRequest(method, path, "NOT FOUND");
    }

    // Add CORS headers
    response.replace("Content-Type: application/json",
                     "Content-Type: application/json\r\n"
                     "Access-Control-Allow-Origin: *");

    socket->write(response.toUtf8());
    socket->close();
}

QString DatabaseServer::createHttpResponse(int statusCode, const QString &body, const QString &contentType)
{
    QString statusText;
    switch (statusCode) {
    case 200: statusText = "OK"; break;
    case 400: statusText = "Bad Request"; break;
    case 401: statusText = "Unauthorized"; break;
    case 404: statusText = "Not Found"; break;
    case 500: statusText = "Internal Server Error"; break;
    default: statusText = "Unknown"; break;
    }

    QString response = QString("HTTP/1.1 %1 %2\r\n"
                               "Content-Type: %3\r\n"
                               "Content-Length: %4\r\n"
                               "Connection: close\r\n"
                               "\r\n"
                               "%5")
                           .arg(statusCode)
                           .arg(statusText)
                           .arg(contentType)
                           .arg(body.length())
                           .arg(body);

    return response;
}

QString DatabaseServer::parseHttpMethod(const QString &request)
{
    QStringList lines = request.split("\r\n");
    if (lines.isEmpty()) return "";

    QStringList parts = lines.first().split(" ");
    return parts.isEmpty() ? "" : parts.first();
}

QString DatabaseServer::parseHttpPath(const QString &request)
{
    QStringList lines = request.split("\r\n");
    if (lines.isEmpty()) return "";

    QStringList parts = lines.first().split(" ");
    return parts.size() > 1 ? parts.at(1) : "";
}

QString DatabaseServer::parseHttpBody(const QString &request)
{
    int bodyStart = request.indexOf("\r\n\r\n");
    if (bodyStart == -1) return "";

    return request.mid(bodyStart + 4);
}

QString DatabaseServer::getHttpHeader(const QString &request, const QString &headerName)
{
    QStringList lines = request.split("\r\n");
    QString headerPrefix = headerName.toLower() + ": "; // Convert to lowercase for comparison

    for (const QString &line : lines) {
        if (line.toLower().startsWith(headerPrefix)) { // Case-insensitive comparison
            return line.mid(line.indexOf(":") + 1).trimmed(); // Get value after ':'
        }
    }

    return "";
}

bool DatabaseServer::authenticate(const QString &password)
{
    return password == m_password;
}

void DatabaseServer::logRequest(const QString &method, const QString &path, const QString &response)
{
    qDebug() << "[" << QDateTime::currentDateTime().toString() << "]"
             << method << path
             << (response.isEmpty() ? "" : "- " + response);
}

QJsonObject DatabaseServer::loadCollection(const QString &collection)
{
    QJsonObject result;
    QString filePath = getCollectionPath(collection);

    QFile file(filePath);
    if (!file.exists()) {
        result["data"] = QJsonArray();
        return result;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open file for reading:" << filePath;
        result["data"] = QJsonArray();
        return result;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error for" << collection << ":" << error.errorString();
        result["data"] = QJsonArray();
        return result;
    }

    result["data"] = doc.array();
    return result;
}

bool DatabaseServer::saveCollection(const QString &collection, const QJsonArray &data)
{
    QString filePath = getCollectionPath(collection);

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Failed to open file for writing:" << filePath;
        return false;
    }

    QJsonDocument doc(data);
    qint64 bytesWritten = file.write(doc.toJson());
    file.close();

    if (bytesWritten == -1) {
        qWarning() << "Failed to write data to file:" << filePath;
        return false;
    }

    return true;
}

QString DatabaseServer::getCollectionPath(const QString &collection)
{
    // Sanitize collection name
    QString sanitized = collection;
    sanitized.replace(QRegularExpression("[^a-zA-Z0-9_-]"), "_");
    return m_dataDirectory + "/" + sanitized + ".json";
}
