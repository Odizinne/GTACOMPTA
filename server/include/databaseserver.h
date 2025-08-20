#ifndef DATABASESERVER_H
#define DATABASESERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QStandardPaths>
#include <QTimer>
#include <QDateTime>
#include <QRegularExpression>

class DatabaseServer : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseServer(QObject *parent = nullptr);
    ~DatabaseServer();

    bool start(quint16 port = 3000);
    void stop();
    void setPassword(const QString &password);
    void setDataDirectory(const QString &path);

private slots:
    void newConnection();
    void readyRead();
    void clientDisconnected();

private:
    QTcpServer *m_server;
    QString m_password;
    QString m_dataDirectory;
    QTimer *m_logTimer;

    bool authenticate(const QString &password);
    void logRequest(const QString &method, const QString &path, const QString &response = "");

    QJsonObject loadCollection(const QString &collection);
    bool saveCollection(const QString &collection, const QJsonArray &data);
    QString getCollectionPath(const QString &collection);

    // HTTP handling
    void handleHttpRequest(QTcpSocket *socket, const QString &request);
    QByteArray createHttpResponse(int statusCode, const QString &body, const QString &contentType = "application/json");
    QString parseHttpMethod(const QString &request);
    QString parseHttpPath(const QString &request);
    QString parseHttpBody(const QString &request);
    QString getHttpHeader(const QString &request, const QString &headerName);
};

#endif // DATABASESERVER_H
