#ifndef AWAITINGTRANSACTIONMODEL_H
#define AWAITINGTRANSACTIONMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class AwaitingTransactionModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        DescriptionRole = Qt::UserRole + 1,
        AmountRole,
        DateRole
    };
    Q_ENUM(Roles)

    explicit AwaitingTransactionModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // AwaitingTransaction-specific methods
    Q_INVOKABLE void addAwaitingTransaction(const QString &description, double amount, const QString &date);
    Q_INVOKABLE void updateAwaitingTransaction(int index, const QString &description, double amount, const QString &date);
    Q_INVOKABLE double getAwaitingTransactionAmount(int index) const;
    Q_INVOKABLE void approveTransaction(int index);

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;

signals:
    void transactionApproved(const QString &description, double amount, const QString &date);

private:
    struct AwaitingTransaction {
        QString description;
        double amount;
        QString date;
    };

    QList<AwaitingTransaction> m_awaitingTransactions;
};

#endif // AWAITINGTRANSACTIONMODEL_H
