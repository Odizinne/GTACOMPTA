#include "transactionmodel.h"

TransactionModel::TransactionModel(QObject *parent)
    : BaseModel("transactions.json", parent)
{
}

int TransactionModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_transactions.size();
}

QVariant TransactionModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_transactions.size())
        return QVariant();

    const Transaction &transaction = m_transactions.at(index.row());

    switch (role) {
    case DescriptionRole:
        return transaction.description;
    case AmountRole:
        return transaction.amount;
    case DateRole:
        return transaction.date;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> TransactionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DescriptionRole] = "description";
    roles[AmountRole] = "amount";
    roles[DateRole] = "date";
    return roles;
}

void TransactionModel::addTransaction(const QString &description, double amount, const QString &date)
{
    beginInsertRows(QModelIndex(), m_transactions.size(), m_transactions.size());
    m_transactions.append({description, amount, date});
    endInsertRows();

    emit countChanged();
    saveToFile();
}

void TransactionModel::updateTransaction(int index, const QString &description, double amount, const QString &date)
{
    if (index < 0 || index >= m_transactions.size())
        return;

    m_transactions[index] = {description, amount, date};
    emit dataChanged(createIndex(index, 0), createIndex(index, 0));
    saveToFile();
}

double TransactionModel::getTransactionAmount(int index) const
{
    if (index < 0 || index >= m_transactions.size())
        return 0.0;

    return m_transactions.at(index).amount;
}

QJsonObject TransactionModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_transactions.size())
        return QJsonObject();

    const Transaction &trans = m_transactions.at(index);
    QJsonObject obj;
    obj["description"] = trans.description;
    obj["amount"] = trans.amount;
    obj["date"] = trans.date;
    return obj;
}

void TransactionModel::entryFromJson(const QJsonObject &obj)
{
    Transaction trans;
    trans.description = obj["description"].toString();
    trans.amount = obj["amount"].toDouble();
    trans.date = obj["date"].toString();
    m_transactions.append(trans);
}

void TransactionModel::addEntryToModel()
{
    // Not used in this implementation
}

void TransactionModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_transactions.removeAt(index);
    endRemoveRows();
}

void TransactionModel::clearModel()
{
    m_transactions.clear();
}

void TransactionModel::addTransactionFromCheckout(const QString &description, double amount)
{
    QString currentDate = QDate::currentDate().toString("yyyy-MM-dd");
    addTransaction(description, amount, currentDate);
}
