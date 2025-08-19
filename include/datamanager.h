#ifndef DATAMANAGER_H
#define DATAMANAGER_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QAbstractListModel>
#include <QQmlEngine>
#include <QJSEngine>
#include <QtQml/qqmlregistration.h>

#include "employeemodel.h"
#include "transactionmodel.h"
#include "awaitingtransactionmodel.h"
#include "clientmodel.h"
#include "supplementmodel.h"
#include "offermodel.h"
#include "basemodel.h"

class DataManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit DataManager(QObject *parent = nullptr);
    ~DataManager() override;

    static DataManager* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);
    static DataManager* instance();

    Q_INVOKABLE bool exportData(const QString &filePath,
                                EmployeeModel *employeeModel,
                                TransactionModel *transactionModel,
                                AwaitingTransactionModel *awaitingTransactionModel,
                                ClientModel *clientModel,
                                SupplementModel *supplementModel,
                                OfferModel *offerModel);

    Q_INVOKABLE bool importData(const QString &filePath,
                                EmployeeModel *employeeModel,
                                TransactionModel *transactionModel,
                                AwaitingTransactionModel *awaitingTransactionModel,
                                ClientModel *clientModel,
                                SupplementModel *supplementModel,
                                OfferModel *offerModel);

    Q_INVOKABLE QString getDefaultExportPath() const;
    Q_INVOKABLE QString getDefaultImportPath() const;

signals:
    void exportCompleted(bool success, const QString &message);
    void importCompleted(bool success, const QString &message);
    void settingsChanged(int money, bool firstRun, const QString &companyName);

private:
    QJsonObject collectAllData(EmployeeModel *employeeModel,
                               TransactionModel *transactionModel,
                               AwaitingTransactionModel *awaitingTransactionModel,
                               ClientModel *clientModel,
                               SupplementModel *supplementModel,
                               OfferModel *offerModel);

    QJsonArray modelToJsonArray(BaseModel *model);
    bool restoreModelFromJsonArray(BaseModel *model, const QJsonArray &array);
    QJsonObject collectUserSettings();
    void restoreUserSettings(const QJsonObject &settings);

    // Encryption/decryption methods
    QByteArray encryptData(const QByteArray &data);
    QByteArray decryptData(const QByteArray &encryptedData);

    static DataManager* m_instance;
};

#endif // DATAMANAGER_H
