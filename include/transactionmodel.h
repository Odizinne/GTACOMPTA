#ifndef TRANSACTIONMODEL_H
#define TRANSACTIONMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class TransactionModel : public BaseModel
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

    enum SortColumns {
        SortByDescription = 0,
        SortByAmount = 1,
        SortByDate = 2
    };
    Q_ENUM(SortColumns)

    explicit TransactionModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Transaction-specific methods
    Q_INVOKABLE void addTransaction(const QString &description, double amount, const QString &date);
    Q_INVOKABLE void updateTransaction(int index, const QString &description, double amount, const QString &date);
    Q_INVOKABLE void addTransactionFromCheckout(const QString &description, double amount);
    Q_INVOKABLE double getTransactionAmount(int index) const;

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

private:
    struct Transaction {
        QString description;
        double amount;
        QString date;
    };

    QList<Transaction> m_transactions;
};

#endif // TRANSACTIONMODEL_H
