#include "versiongetter.h"
#include "version.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QDebug>
#include <QRegularExpression>
#include <QSettings>

VersionGetter* VersionGetter::m_instance = nullptr;

VersionGetter::VersionGetter(QObject* parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_updateAvailable(false)
    , m_checkingForUpdates(false)
    , m_downloadingUpdate(false)
    , m_downloadProgress(0)
{
    m_instance = this;
}

VersionGetter::~VersionGetter()
{
    if (m_currentReply) {
        m_currentReply->abort();
    }

    if (m_instance == this) {
        m_instance = nullptr;
    }
}

VersionGetter* VersionGetter::create(QQmlEngine* qmlEngine, QJSEngine* jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    if (!m_instance) {
        m_instance = new VersionGetter();
    }
    return m_instance;
}

VersionGetter* VersionGetter::instance()
{
    return m_instance;
}

QString VersionGetter::getAppVersion() const
{
    return APP_VERSION_STRING;
}

QString VersionGetter::getQtVersion() const
{
    return QT_VERSION_STRING;
}

QString VersionGetter::getCommitHash() const
{
    return QString(GIT_COMMIT_HASH);
}

QString VersionGetter::getBuildTimestamp() const
{
    return QString(BUILD_TIMESTAMP);
}

void VersionGetter::checkForUpdates()
{
    if (m_checkingForUpdates) {
        return;
    }

    setCheckingForUpdates(true);

    QNetworkRequest request;
    request.setUrl(QUrl("https://api.github.com/repos/Odizinne/GTACOMPTA/releases/latest"));
    request.setHeader(QNetworkRequest::UserAgentHeader, "GTACOMPTA-UpdateChecker/1.0");

    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }

    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &VersionGetter::onUpdateCheckFinished);
}

void VersionGetter::downloadUpdate()
{
    if (m_downloadingUpdate || m_downloadUrl.isEmpty()) {
        return;
    }

    setDownloadingUpdate(true);
    setDownloadProgress(0);

    QNetworkRequest request;
    request.setUrl(QUrl(m_downloadUrl));
    request.setHeader(QNetworkRequest::UserAgentHeader, "GTACOMPTA-UpdateDownloader/1.0");

    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }

    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &VersionGetter::onDownloadFinished);
    connect(m_currentReply, &QNetworkReply::downloadProgress, this, &VersionGetter::onDownloadProgress);
}

void VersionGetter::onUpdateCheckFinished()
{
    setCheckingForUpdates(false);

    if (!m_currentReply) {
        return;
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        emit errorOccurred("Failed to check for updates: " + m_currentReply->errorString());
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        emit errorOccurred("Failed to parse update information: " + error.errorString());
        return;
    }

    QJsonObject release = doc.object();
    QString latestVersion = release["tag_name"].toString();
    QString releaseBody = release["body"].toString();

    if (latestVersion.isEmpty()) {
        emit errorOccurred("No version information found in release data");
        return;
    }

    setLatestVersion(latestVersion);
    setReleaseNotes(releaseBody.isEmpty() ? "No release notes available." : releaseBody);

    QString currentVersion = getAppVersion();
    bool updateAvailable = compareVersions(currentVersion, latestVersion);
    setUpdateAvailable(updateAvailable);

    if (updateAvailable) {
        // Find the installer asset
        QJsonArray assets = release["assets"].toArray();
        for (const QJsonValue& asset : assets) {
            QJsonObject assetObj = asset.toObject();
            QString name = assetObj["name"].toString();

            if (name.contains("installer", Qt::CaseInsensitive) && name.endsWith(".exe", Qt::CaseInsensitive)) {
                m_downloadUrl = assetObj["browser_download_url"].toString();
                break;
            }
        }

        if (m_downloadUrl.isEmpty()) {
            emit errorOccurred("No installer found in the latest release");
        }
    }

    emit updateCheckCompleted(updateAvailable, latestVersion);
}

void VersionGetter::onDownloadFinished()
{
    setDownloadingUpdate(false);
    setDownloadProgress(100);

    if (!m_currentReply) {
        return;
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        emit errorOccurred("Failed to download update: " + m_currentReply->errorString());
        emit downloadCompleted(false, "");
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    // Save the installer to temp directory
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QString fileName = QString("GTACOMPTA_Installer_%1.exe").arg(m_latestVersion);
    QString filePath = QDir(tempDir).filePath(fileName);

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        emit errorOccurred("Failed to save installer: " + file.errorString());
        emit downloadCompleted(false, "");
        return;
    }

    qint64 bytesWritten = file.write(data);
    file.close();

    if (bytesWritten != data.size()) {
        emit errorOccurred("Failed to write complete installer file");
        emit downloadCompleted(false, "");
        return;
    }

    emit downloadCompleted(true, filePath);

    // Launch the installer
    launchExecutable(filePath);
}

void VersionGetter::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        int progress = static_cast<int>((bytesReceived * 100) / bytesTotal);
        setDownloadProgress(progress);
    }
}

bool VersionGetter::compareVersions(const QString& currentVersion, const QString& latestVersion)
{
    // Remove 'v' prefix if present
    QString current = currentVersion;
    QString latest = latestVersion;

    if (current.startsWith('v', Qt::CaseInsensitive)) {
        current = current.mid(1);
    }
    if (latest.startsWith('v', Qt::CaseInsensitive)) {
        latest = latest.mid(1);
    }

    // Split versions into parts
    QStringList currentParts = current.split('.');
    QStringList latestParts = latest.split('.');

    // Ensure both have same number of parts
    while (currentParts.size() < latestParts.size()) {
        currentParts.append("0");
    }
    while (latestParts.size() < currentParts.size()) {
        latestParts.append("0");
    }

    // Compare each part
    for (int i = 0; i < currentParts.size(); ++i) {
        int currentPart = currentParts[i].toInt();
        int latestPart = latestParts[i].toInt();

        if (latestPart > currentPart) {
            return true; // Update available
        } else if (latestPart < currentPart) {
            return false; // Current is newer
        }
        // Continue if equal
    }

    return false; // Versions are equal
}

void VersionGetter::launchExecutable(const QString& filePath)
{
    if (filePath.isEmpty()) {
        emit errorOccurred("No installer file path provided");
        return;
    }

    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        emit errorOccurred("Installer file does not exist: " + filePath);
        return;
    }

    if (!fileInfo.isExecutable()) {
        emit errorOccurred("Installer file is not executable: " + filePath);
        return;
    }

    qDebug() << "Launching installer:" << filePath;

    // Launch the installer and exit the application
    bool success = QProcess::startDetached(filePath);

    if (success) {
        qDebug() << "Installer launched successfully, exiting application";
    } else {
        emit errorOccurred("Failed to launch installer: " + filePath);
    }
}

void VersionGetter::setUpdateAvailable(bool available)
{
    if (m_updateAvailable != available) {
        m_updateAvailable = available;
        emit updateAvailableChanged();
    }
}

void VersionGetter::setLatestVersion(const QString& version)
{
    if (m_latestVersion != version) {
        m_latestVersion = version;
        emit latestVersionChanged();
    }
}

void VersionGetter::setReleaseNotes(const QString& notes)
{
    if (m_releaseNotes != notes) {
        m_releaseNotes = notes;
        emit releaseNotesChanged();
    }
}

void VersionGetter::setCheckingForUpdates(bool checking)
{
    if (m_checkingForUpdates != checking) {
        m_checkingForUpdates = checking;
        emit checkingForUpdatesChanged();
    }
}

void VersionGetter::setDownloadingUpdate(bool downloading)
{
    if (m_downloadingUpdate != downloading) {
        m_downloadingUpdate = downloading;
        emit downloadingUpdateChanged();
    }
}

void VersionGetter::setDownloadProgress(int progress)
{
    if (m_downloadProgress != progress) {
        m_downloadProgress = progress;
        emit downloadProgressChanged();
    }
}
