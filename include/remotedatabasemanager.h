#ifndef REMOTEDATABASEMANAGER_H
#define REMOTEDATABASEMANAGER_H

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtQml/qqmlregistration.h>

class RemoteDatabaseManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit RemoteDatabaseManager(QObject *parent = nullptr);
    static RemoteDatabaseManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static RemoteDatabaseManager* instance();
    static RemoteDatabaseManager* ensureInstance();

    Q_INVOKABLE void saveData(const QString &collection, const QJsonObject &data);
    Q_INVOKABLE void loadData(const QString &collection);
    Q_INVOKABLE void testConnection();

signals:
    void dataLoaded(const QString &collection, const QJsonObject &data);
    void dataSaved(const QString &collection, bool success);
    void connectionResult(bool success, const QString &message);
    void readOnlyStatusChanged(bool isReadOnly);

private slots:
    void handleNetworkReply();

private:
    QNetworkAccessManager *m_networkManager;
    QString getApiUrl(const QString &endpoint) const;
    void makeRequest(const QString &method, const QString &endpoint, const QJsonObject &data = QJsonObject());

    static RemoteDatabaseManager* m_instance;
};

#endif // REMOTEDATABASEMANAGER_H
