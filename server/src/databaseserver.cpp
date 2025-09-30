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
    , m_password("1234")
    , m_userManager(new UserManager(this))
{
    m_dataDirectory = "";
    connect(m_server, &QTcpServer::newConnection, this, &DatabaseServer::newConnection);

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
        qDebug() << "Running in HTTP mode (nginx handles HTTPS)";
        qDebug() << "Password protection enabled";

        m_logTimer->start(30000);
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
    m_userManager->setDataDirectory(m_dataDirectory);
    qDebug() << "Data directory set to:" << m_dataDirectory;
}

void DatabaseServer::newConnection()
{
    while (m_server->hasPendingConnections()) {
        QTcpSocket *tcpSocket = m_server->nextPendingConnection();

        // HTTP mode only - nginx handles HTTPS
        connect(tcpSocket, &QTcpSocket::readyRead, this, &DatabaseServer::readyRead);
        connect(tcpSocket, &QTcpSocket::disconnected, this, &DatabaseServer::clientDisconnected);
        qDebug() << "New HTTP connection from:" << tcpSocket->peerAddress().toString();
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
    QString protocolVersion = getHttpHeader(request, "X-Protocol-Version");
    QString username = getHttpHeader(request, "X-Username");
    QString userPassword = getHttpHeader(request, "X-User-Password");

    QByteArray response;

    // Check protocol version
    if (!protocolVersion.isEmpty() && protocolVersion != "1.0") {
        QJsonObject error;
        error["error"] = "Unsupported protocol version";
        error["serverVersion"] = "1.0";
        error["clientVersion"] = protocolVersion;
        response = createHttpResponse(400, QJsonDocument(error).toJson());
        socket->write(response);
        socket->close();
        logRequest(method, path, "PROTOCOL VERSION MISMATCH");
        return;
    }

    // Server authentication check
    if (!authenticate(authHeader)) {
        QJsonObject error;
        error["error"] = "Unauthorized - Invalid server password";
        response = createHttpResponse(401, QJsonDocument(error).toJson());
        logRequest(method, path, "UNAUTHORIZED - SERVER");
    }
    // User authentication check
    else if (!authenticateRequest(username, userPassword)) {
        QJsonObject error;
        error["error"] = "Unauthorized - Invalid user credentials";
        response = createHttpResponse(401, QJsonDocument(error).toJson());
        logRequest(method, path, "UNAUTHORIZED - USER");
    }
    // Test connection
    else if (method == "GET" && path == "/api/test") {
        QJsonObject result;
        result["success"] = true;
        result["message"] = "Connection successful";
        result["server"] = "GTACOMPTA Server v1.0";
        result["protocolVersion"] = "1.0";
        result["sslEnabled"] = false;
        result["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
        result["username"] = username;
        result["readonly"] = isRequestReadOnly(username);

        response = createHttpResponse(200, QJsonDocument(result).toJson());
        logRequest(method, path, QString("Connection test successful for user: %1").arg(username));
    }
    // Save data - check if user has write permissions
    else if (method == "POST" && path.startsWith("/api/save/")) {
        if (isRequestReadOnly(username)) {
            QJsonObject error;
            error["error"] = "Forbidden - Read-only user cannot save data";
            response = createHttpResponse(403, QJsonDocument(error).toJson());
            logRequest(method, path, QString("FORBIDDEN - User %1 attempted to save").arg(username));
        } else {
            QString collection = path.mid(10);

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
                logRequest(method, path, QString("Save %1 by %2: %3").arg(collection).arg(username).arg(success ? "SUCCESS" : "FAILED"));
            }
        }
    }
    // Load data - allowed for all authenticated users
    else if (method == "GET" && path.startsWith("/api/load/")) {
        QString collection = path.mid(10);

        QJsonObject data = loadCollection(collection);

        // Add readonly status to response
        data["readonly"] = isRequestReadOnly(username);
        data["username"] = username;

        response = createHttpResponse(200, QJsonDocument(data).toJson());
        logRequest(method, path, QString("Load %1 by %2: %3 items").arg(collection).arg(username).arg(data["data"].toArray().size()));
    }
    // Server status
    else if (method == "GET" && path == "/api/status") {
        QJsonObject status;
        status["server"] = "GTACOMPTA Database Server";
        status["version"] = "1.0.0";
        status["protocolVersion"] = "1.0";
        status["sslEnabled"] = false;
        status["uptime"] = QDateTime::currentDateTime().toString(Qt::ISODate);
        status["dataDirectory"] = m_dataDirectory;
        status["username"] = username;
        status["readonly"] = isRequestReadOnly(username);

        QDir dataDir(m_dataDirectory);
        QStringList jsonFiles = dataDir.entryList(QStringList() << "*.json", QDir::Files);
        status["collections"] = jsonFiles.size();

        response = createHttpResponse(200, QJsonDocument(status).toJson());
        logRequest(method, path, QString("Status check by user: %1").arg(username));
    }
    // Not found
    else {
        QJsonObject error;
        error["error"] = "Not found";
        response = createHttpResponse(404, QJsonDocument(error).toJson());
        logRequest(method, path, "NOT FOUND");
    }

    socket->write(response);
    socket->close();
}

QByteArray DatabaseServer::createHttpResponse(int statusCode, const QString &body, const QString &contentType)
{
    QString statusText;
    switch (statusCode) {
    case 200: statusText = "OK"; break;
    case 400: statusText = "Bad Request"; break;
    case 401: statusText = "Unauthorized"; break;
    case 403: statusText = "Forbidden"; break;
    case 404: statusText = "Not Found"; break;
    case 500: statusText = "Internal Server Error"; break;
    default: statusText = "Unknown"; break;
    }

    // Convert body to UTF-8 bytes
    QByteArray bodyBytes = body.toUtf8();

    // Create header as string first
    QString headerStr = QString("HTTP/1.1 %1 %2\r\n"
                                "Content-Type: %3; charset=utf-8\r\n"
                                "Content-Length: %4\r\n"
                                "Connection: close\r\n"
                                "\r\n")
                            .arg(statusCode)
                            .arg(statusText)
                            .arg(contentType)
                            .arg(bodyBytes.size());

    // Convert header to bytes and combine
    QByteArray headerBytes = headerStr.toUtf8();
    return headerBytes + bodyBytes;
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
    QString headerPrefix = headerName.toLower() + ": ";

    for (const QString &line : lines) {
        if (line.toLower().startsWith(headerPrefix)) {
            return line.mid(line.indexOf(":") + 1).trimmed();
        }
    }

    return "";
}

bool DatabaseServer::authenticate(const QString &password)
{
    return password == m_password;
}

bool DatabaseServer::authenticateRequest(const QString &username, const QString &password)
{
    if (username.isEmpty() || password.isEmpty()) {
        return false;
    }

    return m_userManager->authenticateUser(username, password);
}

bool DatabaseServer::isRequestReadOnly(const QString &username)
{
    return m_userManager->isUserReadOnly(username);
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
    QString sanitized = collection;
    sanitized.replace(QRegularExpression("[^a-zA-Z0-9_-]"), "_");
    return m_dataDirectory + "/" + sanitized + ".json";
}
