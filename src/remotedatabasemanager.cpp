#include "remotedatabasemanager.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QDebug>

RemoteDatabaseManager* RemoteDatabaseManager::m_instance = nullptr;

RemoteDatabaseManager::RemoteDatabaseManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    m_instance = this;
}

RemoteDatabaseManager* RemoteDatabaseManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    if (!m_instance) {
        m_instance = new RemoteDatabaseManager();
        qDebug() << "RemoteDatabaseManager singleton created";
    }
    return m_instance;
}

RemoteDatabaseManager* RemoteDatabaseManager::instance()
{
    return m_instance;
}

RemoteDatabaseManager* RemoteDatabaseManager::ensureInstance()
{
    if (!m_instance) {
        m_instance = new RemoteDatabaseManager();
        qDebug() << "RemoteDatabaseManager instance created on demand";
    }
    return m_instance;
}

void RemoteDatabaseManager::saveData(const QString &collection, const QJsonObject &data)
{
    makeRequest("POST", "/api/save/" + collection, data);
}

void RemoteDatabaseManager::loadData(const QString &collection)
{
    makeRequest("GET", "/api/load/" + collection);
}

void RemoteDatabaseManager::testConnection()
{
    makeRequest("GET", "/api/test");
}

QString RemoteDatabaseManager::getApiUrl(const QString &endpoint) const
{
    QSettings settings("Odizinne", "GTACOMPTA");
    QString host = settings.value("remoteHost", "localhost").toString();

    return QString("https://%1%2").arg(host).arg(endpoint);
}

void RemoteDatabaseManager::makeRequest(const QString &method, const QString &endpoint, const QJsonObject &data)
{
    QSettings settings("Odizinne", "GTACOMPTA");
    QString password = settings.value("remotePassword", "1234").toString();

    QString url = getApiUrl(endpoint);
    qDebug() << "Making request:" << method << url;
    qDebug() << "Using password:" << password;

    QNetworkRequest request;
    request.setUrl(QUrl(url));
    request.setRawHeader("X-Password", password.toUtf8());
    request.setRawHeader("Content-Type", "application/json");
    request.setRawHeader("X-Protocol-Version", "1.0"); // Add this line

    // Safe header debugging - convert to QString properly
    qDebug() << "Headers set:";
    qDebug() << "  X-Password:" << QString::fromUtf8(request.rawHeader("X-Password"));
    qDebug() << "  Content-Type:" << QString::fromUtf8(request.rawHeader("Content-Type"));
    qDebug() << "  X-Protocol-Version:" << QString::fromUtf8(request.rawHeader("X-Protocol-Version"));

    QNetworkReply *reply = nullptr;

    if (method == "GET") {
        reply = m_networkManager->get(request);
    } else if (method == "POST") {
        QJsonDocument doc(data);
        reply = m_networkManager->post(request, doc.toJson());
    }

    if (reply) {
        reply->setProperty("endpoint", endpoint);
        connect(reply, &QNetworkReply::finished, this, &RemoteDatabaseManager::handleNetworkReply);
    }
}

void RemoteDatabaseManager::handleNetworkReply()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    QString endpoint = reply->property("endpoint").toString();
    QByteArray responseData = reply->readAll();

    qDebug() << "Network reply for endpoint:" << endpoint;
    qDebug() << "HTTP status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Network error:" << reply->errorString();

        if (endpoint.contains("/test")) {
            emit connectionResult(false, reply->errorString());
        } else if (endpoint.contains("/save/")) {
            QString collection = endpoint.split("/").last();
            emit dataSaved(collection, false);
        }
        return;
    }

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(responseData, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << parseError.errorString();
        qWarning() << "Response was:" << responseData;
        return;
    }

    QJsonObject response = doc.object();

    if (endpoint.contains("/test")) {
        qDebug() << "About to emit connectionResult";
        emit connectionResult(true, response["message"].toString());
    } else if (endpoint.contains("/save/")) {
        QString collection = endpoint.split("/").last();
        qDebug() << "About to emit dataSaved for:" << collection;
        emit dataSaved(collection, response["success"].toBool());
    } else if (endpoint.contains("/load/")) {
        QString collection = endpoint.split("/").last();
        qDebug() << "About to emit dataLoaded for collection:" << collection;
        qDebug() << "Signal emitter pointer:" << this;
        qDebug() << "Number of connections to dataLoaded signal:" << receivers(SIGNAL(dataLoaded(QString,QJsonObject)));
        emit dataLoaded(collection, response);
        qDebug() << "dataLoaded signal emitted";
    }
}
