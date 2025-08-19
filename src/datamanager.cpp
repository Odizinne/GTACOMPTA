#include "datamanager.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSettings>
#include <QDebug>
#include <QCryptographicHash>
#include <QDateTime>

DataManager* DataManager::m_instance = nullptr;

DataManager::DataManager(QObject *parent)
    : QObject(parent)
{
    m_instance = this;
}

DataManager::~DataManager()
{
    if (m_instance == this) {
        m_instance = nullptr;
    }
}

DataManager* DataManager::create(QQmlEngine* qmlEngine, QJSEngine* jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    if (!m_instance) {
        m_instance = new DataManager();
    }
    return m_instance;
}

DataManager* DataManager::instance()
{
    return m_instance;
}

bool DataManager::exportData(const QString &filePath,
                             EmployeeModel *employeeModel,
                             TransactionModel *transactionModel,
                             AwaitingTransactionModel *awaitingTransactionModel,
                             ClientModel *clientModel,
                             SupplementModel *supplementModel,
                             OfferModel *offerModel)
{
    if (filePath.isEmpty()) {
        emit exportCompleted(false, "File path is empty");
        return false;
    }

    try {
        QJsonObject rootObject = collectAllData(employeeModel, transactionModel,
                                                awaitingTransactionModel, clientModel,
                                                supplementModel, offerModel);

        QJsonDocument doc(rootObject);
        QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

        // Encrypt the data
        QByteArray encryptedData = encryptData(jsonData);

        // Ensure directory exists
        QFileInfo fileInfo(filePath);
        QDir().mkpath(fileInfo.absolutePath());

        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            emit exportCompleted(false, "Could not open file for writing: " + file.errorString());
            return false;
        }

        qint64 bytesWritten = file.write(encryptedData);
        file.close();

        if (bytesWritten == -1) {
            emit exportCompleted(false, "Failed to write data to file");
            return false;
        }

        emit exportCompleted(true, "Data exported successfully to " + filePath);
        return true;

    } catch (const std::exception &e) {
        emit exportCompleted(false, "Export failed: " + QString::fromStdString(e.what()));
        return false;
    }
}

bool DataManager::importData(const QString &filePath,
                             EmployeeModel *employeeModel,
                             TransactionModel *transactionModel,
                             AwaitingTransactionModel *awaitingTransactionModel,
                             ClientModel *clientModel,
                             SupplementModel *supplementModel,
                             OfferModel *offerModel)
{
    if (filePath.isEmpty()) {
        emit importCompleted(false, "File path is empty");
        return false;
    }

    QFile file(filePath);
    if (!file.exists()) {
        emit importCompleted(false, "File does not exist: " + filePath);
        return false;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        emit importCompleted(false, "Could not open file for reading: " + file.errorString());
        return false;
    }

    try {
        QByteArray encryptedData = file.readAll();
        file.close();

        // Decrypt the data
        QByteArray jsonData = decryptData(encryptedData);
        if (jsonData.isEmpty()) {
            emit importCompleted(false, "Failed to decrypt file or invalid file format");
            return false;
        }

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

        if (error.error != QJsonParseError::NoError) {
            emit importCompleted(false, "Invalid backup file format or corrupted data");
            return false;
        }

        QJsonObject rootObject = doc.object();

        // Verify this is a valid GTACOMPTA backup
        if (!rootObject.contains("application") || rootObject["application"].toString() != "GTACOMPTA") {
            emit importCompleted(false, "This is not a valid GTACOMPTA backup file");
            return false;
        }

        // Restore user settings first
        if (rootObject.contains("userSettings")) {
            restoreUserSettings(rootObject["userSettings"].toObject());
        }

        // Clear all models before importing
        if (employeeModel) employeeModel->clear();
        if (transactionModel) transactionModel->clear();
        if (awaitingTransactionModel) awaitingTransactionModel->clear();
        if (clientModel) clientModel->clear();
        if (supplementModel) supplementModel->clear();
        if (offerModel) offerModel->clear();

        // Restore model data
        bool success = true;
        if (rootObject.contains("employees")) {
            success &= restoreModelFromJsonArray(employeeModel, rootObject["employees"].toArray());
        }
        if (rootObject.contains("transactions")) {
            success &= restoreModelFromJsonArray(transactionModel, rootObject["transactions"].toArray());
        }
        if (rootObject.contains("awaitingTransactions")) {
            success &= restoreModelFromJsonArray(awaitingTransactionModel, rootObject["awaitingTransactions"].toArray());
        }
        if (rootObject.contains("clients")) {
            success &= restoreModelFromJsonArray(clientModel, rootObject["clients"].toArray());
        }
        if (rootObject.contains("supplements")) {
            success &= restoreModelFromJsonArray(supplementModel, rootObject["supplements"].toArray());
        }
        if (rootObject.contains("offers")) {
            success &= restoreModelFromJsonArray(offerModel, rootObject["offers"].toArray());
        }

        if (success) {
            emit importCompleted(true, "Data imported successfully from " + filePath);
        } else {
            emit importCompleted(false, "Some data could not be imported properly");
        }

        return success;

    } catch (const std::exception &e) {
        emit importCompleted(false, "Import failed: " + QString::fromStdString(e.what()));
        return false;
    }
}

QString DataManager::getDefaultExportPath() const
{
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    return documentsPath + "/GTACOMPTA_backup.gco";
}

QString DataManager::getDefaultImportPath() const
{
    return getDefaultExportPath();
}

QByteArray DataManager::encryptData(const QByteArray &data)
{
    // Create a signature to verify the file is valid
    QByteArray signature = "GTACOMPTA_V1";

    // Generate a key based on a fixed string + data length (simple but effective)
    QString keyBase = "GTACOMPTA_KEY_2025_SECURE_BACKUP";
    QByteArray key = QCryptographicHash::hash((keyBase + QString::number(data.size())).toUtf8(),
                                              QCryptographicHash::Sha256);

    QByteArray encrypted;
    encrypted.append(signature); // Add signature at the beginning

    // XOR encryption with key rotation
    for (int i = 0; i < data.size(); ++i) {
        quint8 keyByte = static_cast<quint8>(key.at(i % key.size()));
        quint8 dataByte = static_cast<quint8>(data.at(i));

        // Add some extra obfuscation by rotating the key byte
        keyByte = static_cast<quint8>((keyByte + i) % 256);

        encrypted.append(static_cast<char>(dataByte ^ keyByte));
    }

    return encrypted;
}

QByteArray DataManager::decryptData(const QByteArray &encryptedData)
{
    QByteArray signature = "GTACOMPTA_V1";

    // Check minimum size and signature
    if (encryptedData.size() < signature.size() + 10) {
        return QByteArray(); // Too small to be valid
    }

    // Verify signature
    if (!encryptedData.startsWith(signature)) {
        return QByteArray(); // Invalid signature
    }

    // Extract the encrypted content (without signature)
    QByteArray content = encryptedData.mid(signature.size());

    // We need to try different key lengths since we don't know the original data size
    // Try reasonable data sizes (most backups will be between 1KB and 10MB)
    for (int estimatedSize = content.size() - 100; estimatedSize <= content.size() + 100; ++estimatedSize) {
        if (estimatedSize <= 0) continue;

        QString keyBase = "GTACOMPTA_KEY_2025_SECURE_BACKUP";
        QByteArray key = QCryptographicHash::hash((keyBase + QString::number(estimatedSize)).toUtf8(),
                                                  QCryptographicHash::Sha256);

        QByteArray decrypted;

        // XOR decryption with key rotation
        for (int i = 0; i < content.size(); ++i) {
            quint8 keyByte = static_cast<quint8>(key.at(i % key.size()));
            quint8 encryptedByte = static_cast<quint8>(content.at(i));

            // Apply the same key rotation as in encryption
            keyByte = static_cast<quint8>((keyByte + i) % 256);

            decrypted.append(static_cast<char>(encryptedByte ^ keyByte));
        }

        // Try to parse as JSON to verify it's correct
        QJsonParseError error;
        QJsonDocument testDoc = QJsonDocument::fromJson(decrypted, &error);

        if (error.error == QJsonParseError::NoError && !testDoc.isNull()) {
            QJsonObject obj = testDoc.object();
            // Double-check it's a valid GTACOMPTA file
            if (obj.contains("application") && obj["application"].toString() == "GTACOMPTA") {
                return decrypted;
            }
        }
    }

    return QByteArray(); // Decryption failed
}

QJsonObject DataManager::collectAllData(EmployeeModel *employeeModel,
                                        TransactionModel *transactionModel,
                                        AwaitingTransactionModel *awaitingTransactionModel,
                                        ClientModel *clientModel,
                                        SupplementModel *supplementModel,
                                        OfferModel *offerModel)
{
    QJsonObject rootObject;

    // Add metadata
    rootObject["version"] = "1.0";
    rootObject["exportDate"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    rootObject["application"] = "GTACOMPTA";

    // Add user settings
    rootObject["userSettings"] = collectUserSettings();

    // Add model data
    if (employeeModel) {
        rootObject["employees"] = modelToJsonArray(employeeModel);
    }
    if (transactionModel) {
        rootObject["transactions"] = modelToJsonArray(transactionModel);
    }
    if (awaitingTransactionModel) {
        rootObject["awaitingTransactions"] = modelToJsonArray(awaitingTransactionModel);
    }
    if (clientModel) {
        rootObject["clients"] = modelToJsonArray(clientModel);
    }
    if (supplementModel) {
        rootObject["supplements"] = modelToJsonArray(supplementModel);
    }
    if (offerModel) {
        rootObject["offers"] = modelToJsonArray(offerModel);
    }

    return rootObject;
}

QJsonArray DataManager::modelToJsonArray(BaseModel *model)
{
    QJsonArray array;

    if (!model) {
        return array;
    }

    for (int i = 0; i < model->rowCount(); ++i) {
        QJsonObject entry = model->entryToJson(i);
        if (!entry.isEmpty()) {
            array.append(entry);
        }
    }

    return array;
}

bool DataManager::restoreModelFromJsonArray(BaseModel *model, const QJsonArray &array)
{
    if (!model) {
        return false;
    }

    try {
        model->beginResetModel();
        model->clearModel();

        for (const QJsonValue &value : array) {
            QJsonObject obj = value.toObject();
            model->entryFromJson(obj);
        }

        model->endResetModel();
        model->saveToFile();
        return true;

    } catch (const std::exception &) {
        return false;
    }
}

QJsonObject DataManager::collectUserSettings()
{
    QJsonObject settings;

    // We need to read from QSettings since UserSettings.qml uses Settings
    QSettings qsettings("Odizinne", "GTACOMPTA");
    settings["money"] = qsettings.value("money", 0).toInt();
    settings["firstRun"] = qsettings.value("firstRun", true).toBool();
    settings["companyName"] = qsettings.value("companyName", "").toString();

    return settings;
}

void DataManager::restoreUserSettings(const QJsonObject &settings)
{
    emit settingsChanged(settings["money"].toInt(),
                         settings["firstRun"].toBool(),
                         settings["companyName"].toString());
}

// Add these methods to DataManager implementation:

bool DataManager::exportDataToString(EmployeeModel *employeeModel,
                                     TransactionModel *transactionModel,
                                     AwaitingTransactionModel *awaitingTransactionModel,
                                     ClientModel *clientModel,
                                     SupplementModel *supplementModel,
                                     OfferModel *offerModel)
{
    try {
        QJsonObject rootObject = collectAllData(employeeModel, transactionModel,
                                                awaitingTransactionModel, clientModel,
                                                supplementModel, offerModel);

        QJsonDocument doc(rootObject);
        QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

        // Encrypt the data
        QByteArray encryptedData = encryptData(jsonData);
        QString base64Data = encryptedData.toBase64();

        // Generate filename with timestamp
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss");
        QString fileName = QString("GTACOMPTA_backup_%1.gco").arg(timestamp);

        emit exportDataReady(base64Data, fileName);
        emit exportCompleted(true, "Data prepared for download");
        return true;

    } catch (const std::exception &e) {
        emit exportCompleted(false, "Export failed: " + QString::fromStdString(e.what()));
        return false;
    }
}

bool DataManager::importDataFromString(const QString &data,
                                       EmployeeModel *employeeModel,
                                       TransactionModel *transactionModel,
                                       AwaitingTransactionModel *awaitingTransactionModel,
                                       ClientModel *clientModel,
                                       SupplementModel *supplementModel,
                                       OfferModel *offerModel)
{
    try {
        // Decode from base64
        QByteArray encryptedData = QByteArray::fromBase64(data.toUtf8());

        // Decrypt the data
        QByteArray jsonData = decryptData(encryptedData);
        if (jsonData.isEmpty()) {
            emit importCompleted(false, "Failed to decrypt file or invalid file format");
            return false;
        }

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

        if (error.error != QJsonParseError::NoError) {
            emit importCompleted(false, "Invalid backup file format or corrupted data");
            return false;
        }

        QJsonObject rootObject = doc.object();

        // Verify this is a valid GTACOMPTA backup
        if (!rootObject.contains("application") || rootObject["application"].toString() != "GTACOMPTA") {
            emit importCompleted(false, "This is not a valid GTACOMPTA backup file");
            return false;
        }

        // Restore user settings first
        if (rootObject.contains("userSettings")) {
            restoreUserSettings(rootObject["userSettings"].toObject());
        }

        // Clear all models before importing
        if (employeeModel) employeeModel->clear();
        if (transactionModel) transactionModel->clear();
        if (awaitingTransactionModel) awaitingTransactionModel->clear();
        if (clientModel) clientModel->clear();
        if (supplementModel) supplementModel->clear();
        if (offerModel) offerModel->clear();

        // Restore model data
        bool success = true;
        if (rootObject.contains("employees")) {
            success &= restoreModelFromJsonArray(employeeModel, rootObject["employees"].toArray());
        }
        if (rootObject.contains("transactions")) {
            success &= restoreModelFromJsonArray(transactionModel, rootObject["transactions"].toArray());
        }
        if (rootObject.contains("awaitingTransactions")) {
            success &= restoreModelFromJsonArray(awaitingTransactionModel, rootObject["awaitingTransactions"].toArray());
        }
        if (rootObject.contains("clients")) {
            success &= restoreModelFromJsonArray(clientModel, rootObject["clients"].toArray());
        }
        if (rootObject.contains("supplements")) {
            success &= restoreModelFromJsonArray(supplementModel, rootObject["supplements"].toArray());
        }
        if (rootObject.contains("offers")) {
            success &= restoreModelFromJsonArray(offerModel, rootObject["offers"].toArray());
        }

        if (success) {
            emit importCompleted(true, "Data imported successfully");
        } else {
            emit importCompleted(false, "Some data could not be imported properly");
        }

        return success;

    } catch (const std::exception &e) {
        emit importCompleted(false, "Import failed: " + QString::fromStdString(e.what()));
        return false;
    }
}
