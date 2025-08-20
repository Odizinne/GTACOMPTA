#include "basemodel.h"
#include "remotedatabasemanager.h"
#include <QDebug>

BaseModel::BaseModel(const QString &fileName, QObject *parent)
    : QAbstractListModel(parent)
    , m_fileName(fileName)
    , m_sortColumn(0)
    , m_sortAscending(true)
    , m_isLoading(false)
{
    qDebug() << "BaseModel created for" << m_fileName;
}

int BaseModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0; // Override in derived classes
}

void BaseModel::removeEntry(int index)
{
    if (index < 0 || index >= rowCount())
        return;

    removeEntryFromModel(index);
    emit countChanged();
    saveToFile();
}

void BaseModel::ensureRemoteConnection()
{
    RemoteDatabaseManager *remoteManager = RemoteDatabaseManager::instance();
    if (remoteManager) {
        // Use Qt::UniqueConnection to prevent duplicate connections
        bool connected1 = connect(remoteManager, &RemoteDatabaseManager::dataLoaded,
                                  this, &BaseModel::onRemoteDataLoaded, Qt::UniqueConnection);
        bool connected2 = connect(remoteManager, &RemoteDatabaseManager::dataSaved,
                                  this, &BaseModel::onRemoteDataSaved, Qt::UniqueConnection);

        qDebug() << "BaseModel" << m_fileName << "connected to RemoteDatabaseManager";
        qDebug() << "dataLoaded connection:" << connected1;
        qDebug() << "dataSaved connection:" << connected2;
        qDebug() << "RemoteManager pointer:" << remoteManager;
    }
}

void BaseModel::loadFromFile(bool remote)
{
    if (m_isLoading) {
        qDebug() << "Already loading" << m_fileName << "- skipping";
        return; // Prevent recursion
    }

    m_isLoading = true;

    qDebug() << "Loading" << m_fileName << "- useRemote:" << remote;

    if (remote) {
        loadFromRemote();
    } else {
        loadFromLocal();
    }

    m_isLoading = false;
}

void BaseModel::loadFromLocal()
{
#ifdef Q_OS_WASM
    // Use QSettings for WebAssembly (IndexedDB backend)
    QSettings settings("Odizinne", "GTACOMPTA");
    QByteArray jsonData = settings.value(m_fileName).toByteArray();

    if (jsonData.isEmpty()) {
        qDebug() << "No local data found for:" << m_fileName;
        return;
    }

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << error.errorString();
        return;
    }

    beginResetModel();
    clearModel();

    QJsonArray array = doc.array();
    for (const QJsonValue &value : array) {
        QJsonObject obj = value.toObject();
        entryFromJson(obj);
    }

    // Sort after loading
    performSort();

    endResetModel();
    emit countChanged();
#else
    // Use file system for other platforms
    QString filePath = getDataFilePath();
    QFile file(filePath);

    if (!file.exists()) {
        qDebug() << "No local data file found:" << filePath;
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open file for reading:" << filePath;
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << error.errorString();
        return;
    }

    beginResetModel();
    clearModel();

    QJsonArray array = doc.array();
    for (const QJsonValue &value : array) {
        QJsonObject obj = value.toObject();
        entryFromJson(obj);
    }

    // Sort after loading
    performSort();

    endResetModel();
    emit countChanged();
#endif
}

void BaseModel::loadFromRemote()
{
    ensureRemoteConnection(); // Make sure THIS model is connected

    RemoteDatabaseManager *remoteManager = RemoteDatabaseManager::instance();
    if (remoteManager) {
        qDebug() << "Loading from remote:" << m_fileName << "using instance:" << remoteManager;
        remoteManager->loadData(m_fileName); // Back to original
    } else {
        qWarning() << "RemoteDatabaseManager not available, falling back to local";
        loadFromLocal();
    }
}

void BaseModel::clear()
{
    if (rowCount() == 0)
        return;

    beginResetModel();
    clearModel();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void BaseModel::sortBy(int column)
{
    if (m_sortColumn == column) {
        m_sortAscending = !m_sortAscending;
        emit sortAscendingChanged();
    } else {
        m_sortColumn = column;
        m_sortAscending = true;
        emit sortColumnChanged();
        emit sortAscendingChanged();
    }

    beginResetModel();
    performSort();
    endResetModel();
}

void BaseModel::saveToFile()
{
    QJsonArray array;

    for (int i = 0; i < rowCount(); ++i) {
        array.append(entryToJson(i));
    }

    QSettings settings("Odizinne", "GTACOMPTA");
    bool useRemote = settings.value("useRemoteDatabase", false).toBool();

    if (useRemote) {
        ensureRemoteConnection(); // Make sure THIS model is connected for saving too

        // Save to remote database
        RemoteDatabaseManager *remoteManager = RemoteDatabaseManager::instance();
        if (remoteManager) {
            QJsonObject payload;
            payload["data"] = array;
            qDebug() << "Saving to remote:" << m_fileName;
            remoteManager->saveData(m_fileName, payload); // Back to original
        } else {
            qWarning() << "RemoteDatabaseManager not available, falling back to local";
            saveToLocal(array);
        }
    } else {
        // Save locally
        saveToLocal(array);
    }
}

void BaseModel::saveToLocal(const QJsonArray &array)
{
    QJsonDocument doc(array);

#ifdef Q_OS_WASM
    // Use QSettings for WebAssembly (IndexedDB backend)
    QSettings settings("Odizinne", "GTACOMPTA");
    settings.setValue(m_fileName, doc.toJson(QJsonDocument::Compact));
    settings.sync(); // Important for WebAssembly to ensure data is persisted
#else
    // Use file system for other platforms
    QString filePath = getDataFilePath();
    QFileInfo fileInfo(filePath);
    QDir().mkpath(fileInfo.absolutePath());

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Could not open file for writing:" << filePath;
        return;
    }

    file.write(doc.toJson());
    file.close();
#endif
}

void BaseModel::onRemoteDataLoaded(const QString &collection, const QJsonObject &data)
{
    qDebug() << "onRemoteDataLoaded called for collection:" << collection << "my filename:" << m_fileName;

    if (collection != m_fileName) { // Back to original comparison
        return;
    }

    qDebug() << "Processing remote data for:" << collection;

    beginResetModel();
    clearModel();

    QJsonArray array = data["data"].toArray();
    qDebug() << "Array size:" << array.size();

    for (const QJsonValue &value : array) {
        QJsonObject obj = value.toObject();
        entryFromJson(obj);
    }

    // Sort after loading
    performSort();

    endResetModel();
    emit countChanged();

    qDebug() << "Model reset complete for" << m_fileName << ". New row count:" << rowCount();
}

void BaseModel::onRemoteDataSaved(const QString &collection, bool success)
{
    if (collection != m_fileName) return; // Back to original comparison

    qDebug() << "Remote save result for" << collection << ":" << (success ? "SUCCESS" : "FAILED");

    if (!success) {
        qWarning() << "Failed to save to remote, consider fallback to local storage";
        // Could implement fallback logic here
    }
}

QString BaseModel::getDataFilePath() const
{
#ifdef Q_OS_WASM
    // For WebAssembly, this is only used as a key identifier
    // The actual storage is handled by QSettings
    return m_fileName;
#else
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return dataPath + "/" + m_fileName;
#endif
}
