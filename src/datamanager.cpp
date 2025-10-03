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
                             OfferModel *offerModel,
                             CompanySummaryModel *companySummaryModel,
                             NoteModel *noteModel)
{
    if (filePath.isEmpty()) {
        emit exportCompleted(false, "File path is empty");
        return false;
    }

    try {
        QJsonObject rootObject = collectAllData(employeeModel, transactionModel,
                                                awaitingTransactionModel, clientModel,
                                                supplementModel, offerModel,
                                                companySummaryModel, noteModel);

        QJsonDocument doc(rootObject);
        QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

        QFileInfo fileInfo(filePath);
        QDir().mkpath(fileInfo.absolutePath());

        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            emit exportCompleted(false, "Could not open file for writing: " + file.errorString());
            return false;
        }

        qint64 bytesWritten = file.write(jsonData);
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
                             OfferModel *offerModel,
                             CompanySummaryModel *companySummaryModel,
                             NoteModel *noteModel)
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
        QByteArray jsonData = file.readAll();
        file.close();

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

        if (error.error != QJsonParseError::NoError) {
            emit importCompleted(false, "Invalid backup file format: " + error.errorString());
            return false;
        }

        QJsonObject rootObject = doc.object();

        if (!rootObject.contains("application") || rootObject["application"].toString() != "GTACOMPTA") {
            emit importCompleted(false, "This is not a valid GTACOMPTA backup file");
            return false;
        }

        if (rootObject.contains("userSettings")) {
            restoreUserSettings(rootObject["userSettings"].toObject());
        }

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
        if (rootObject.contains("companySummary")) {
            success &= restoreModelFromJsonArray(companySummaryModel, rootObject["companySummary"].toArray());
        }
        if (rootObject.contains("notes")) {
            success &= restoreModelFromJsonArray(noteModel, rootObject["notes"].toArray());
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

bool DataManager::exportDataToString(EmployeeModel *employeeModel,
                                     TransactionModel *transactionModel,
                                     AwaitingTransactionModel *awaitingTransactionModel,
                                     ClientModel *clientModel,
                                     SupplementModel *supplementModel,
                                     OfferModel *offerModel,
                                     CompanySummaryModel *companySummaryModel,
                                     NoteModel *noteModel)
{
    try {
        QJsonObject rootObject = collectAllData(employeeModel, transactionModel,
                                                awaitingTransactionModel, clientModel,
                                                supplementModel, offerModel,
                                                companySummaryModel, noteModel);

        QJsonDocument doc(rootObject);
        QByteArray jsonData = doc.toJson(QJsonDocument::Compact);
        QString jsonString = QString::fromUtf8(jsonData);

        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss");
        QString fileName = QString("GTACOMPTA_backup_%1.gco").arg(timestamp);

        emit exportDataReady(jsonString, fileName);
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
                                       OfferModel *offerModel,
                                       CompanySummaryModel *companySummaryModel,
                                       NoteModel *noteModel)
{
    try {
        QByteArray jsonData = data.toUtf8();

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

        if (error.error != QJsonParseError::NoError) {
            emit importCompleted(false, "Invalid backup file format: " + error.errorString());
            return false;
        }

        QJsonObject rootObject = doc.object();

        if (!rootObject.contains("application") || rootObject["application"].toString() != "GTACOMPTA") {
            emit importCompleted(false, "This is not a valid GTACOMPTA backup file");
            return false;
        }

        if (rootObject.contains("userSettings")) {
            restoreUserSettings(rootObject["userSettings"].toObject());
        }

        if (employeeModel) employeeModel->clear();
        if (transactionModel) transactionModel->clear();
        if (awaitingTransactionModel) awaitingTransactionModel->clear();
        if (clientModel) clientModel->clear();
        if (supplementModel) supplementModel->clear();
        if (offerModel) offerModel->clear();
        if (companySummaryModel) companySummaryModel->clear();
        if (noteModel) noteModel->clear();

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
        if (rootObject.contains("companySummary")) {
            success &= restoreModelFromJsonArray(companySummaryModel, rootObject["companySummary"].toArray());
        }
        if (rootObject.contains("notes")) {
            success &= restoreModelFromJsonArray(noteModel, rootObject["notes"].toArray());
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

QJsonObject DataManager::collectAllData(EmployeeModel *employeeModel,
                                        TransactionModel *transactionModel,
                                        AwaitingTransactionModel *awaitingTransactionModel,
                                        ClientModel *clientModel,
                                        SupplementModel *supplementModel,
                                        OfferModel *offerModel,
                                        CompanySummaryModel *companySummaryModel,
                                        NoteModel *noteModel)
{
    QJsonObject rootObject;

    rootObject["version"] = "1.0";
    rootObject["exportDate"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    rootObject["application"] = "GTACOMPTA";

    rootObject["userSettings"] = collectUserSettings();

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
    if (companySummaryModel) {
        rootObject["companySummary"] = modelToJsonArray(companySummaryModel);
    }
    if (noteModel) {
        rootObject["notes"] = modelToJsonArray(noteModel);
    }

    return rootObject;
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

    QSettings qsettings("Odizinne", "GTACOMPTA");
    settings["firstRun"] = qsettings.value("firstRun", true).toBool();
    settings["notes"] = qsettings.value("notes", "").toString();
    settings["darkMode"] = qsettings.value("darkMode", true).toBool();
    settings["useRemoteDatabase"] = qsettings.value("useRemoteDatabase", false).toBool();
    settings["remoteHost"] = qsettings.value("remoteHost", "localhost").toString();

    return settings;
}

void DataManager::restoreUserSettings(const QJsonObject &settings)
{
    emit settingsChanged(0, // money now comes only from CompanySummaryModel
                         settings["firstRun"].toBool(),
                         "", // companyName only from CompanySummaryModel
                         settings["notes"].toString(),
                         0.5);
}
