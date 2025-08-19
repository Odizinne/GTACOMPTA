#ifndef VERSIONGETTER_H
#define VERSIONGETTER_H

#include <QObject>
#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>

class VersionGetter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY releaseNotesChanged)
    Q_PROPERTY(bool checkingForUpdates READ checkingForUpdates NOTIFY checkingForUpdatesChanged)
    Q_PROPERTY(bool downloadingUpdate READ downloadingUpdate NOTIFY downloadingUpdateChanged)
    Q_PROPERTY(int downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)

public:
    explicit VersionGetter(QObject* parent = nullptr);
    ~VersionGetter() override;

    static VersionGetter* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);
    static VersionGetter* instance();

    Q_INVOKABLE QString getAppVersion() const;
    Q_INVOKABLE QString getQtVersion() const;
    Q_INVOKABLE QString getCommitHash() const;
    Q_INVOKABLE QString getBuildTimestamp() const;

    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadUpdate();

    bool updateAvailable() const { return m_updateAvailable; }
    QString latestVersion() const { return m_latestVersion; }
    QString releaseNotes() const { return m_releaseNotes; }
    bool checkingForUpdates() const { return m_checkingForUpdates; }
    bool downloadingUpdate() const { return m_downloadingUpdate; }
    int downloadProgress() const { return m_downloadProgress; }

signals:
    void updateAvailableChanged();
    void latestVersionChanged();
    void releaseNotesChanged();
    void checkingForUpdatesChanged();
    void downloadingUpdateChanged();
    void downloadProgressChanged();
    void updateCheckCompleted(bool updateAvailable, const QString& latestVersion);
    void downloadCompleted(bool success, const QString& filePath);
    void errorOccurred(const QString& error);

private slots:
    void onUpdateCheckFinished();
    void onDownloadFinished();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    bool compareVersions(const QString& currentVersion, const QString& latestVersion);
    void launchExecutable(const QString& filePath);
    void setUpdateAvailable(bool available);
    void setLatestVersion(const QString& version);
    void setReleaseNotes(const QString& notes);
    void setCheckingForUpdates(bool checking);
    void setDownloadingUpdate(bool downloading);
    void setDownloadProgress(int progress);

    static VersionGetter* m_instance;
    QNetworkAccessManager* m_networkManager;
    QNetworkReply* m_currentReply;

    bool m_updateAvailable;
    QString m_latestVersion;
    QString m_releaseNotes;
    bool m_checkingForUpdates;
    bool m_downloadingUpdate;
    int m_downloadProgress;
    QString m_downloadUrl;
};

#endif // VERSIONGETTER_H
