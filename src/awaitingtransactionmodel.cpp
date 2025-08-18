#include "awaitingtransactionmodel.h"
#include <algorithm>

AwaitingTransactionModel::AwaitingTransactionModel(QObject *parent)
    : BaseModel("awaiting_transactions.json", parent)
{
    m_sortColumn = SortByDate; // Default sort by date
}

int AwaitingTransactionModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_awaitingTransactions.size();
}

QVariant AwaitingTransactionModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_awaitingTransactions.size())
        return QVariant();

    const AwaitingTransaction &transaction = m_awaitingTransactions.at(index.row());

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

QHash<int, QByteArray> AwaitingTransactionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DescriptionRole] = "description";
    roles[AmountRole] = "amount";
    roles[DateRole] = "date";
    return roles;
}

void AwaitingTransactionModel::addAwaitingTransaction(const QString &description, double amount, const QString &date)
{
    beginInsertRows(QModelIndex(), m_awaitingTransactions.size(), m_awaitingTransactions.size());
    m_awaitingTransactions.append({description, amount, date});
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void AwaitingTransactionModel::updateAwaitingTransaction(int index, const QString &description, double amount, const QString &date)
{
    if (index < 0 || index >= m_awaitingTransactions.size())
        return;

    m_awaitingTransactions[index] = {description, amount, date};

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

double AwaitingTransactionModel::getAwaitingTransactionAmount(int index) const
{
    if (index < 0 || index >= m_awaitingTransactions.size())
        return 0.0;

    return m_awaitingTransactions.at(index).amount;
}

void AwaitingTransactionModel::approveTransaction(int index)
{
    if (index < 0 || index >= m_awaitingTransactions.size())
        return;

    const AwaitingTransaction &transaction = m_awaitingTransactions.at(index);

    // Emit signal to add to real transaction model
    emit transactionApproved(transaction.description, transaction.amount, transaction.date);

    // Remove from awaiting list
    removeEntry(index);
}

void AwaitingTransactionModel::performSort()
{
    std::sort(m_awaitingTransactions.begin(), m_awaitingTransactions.end(), [this](const AwaitingTransaction &a, const AwaitingTransaction &b) {
        bool result = false;

        switch (m_sortColumn) {
        case SortByDescription:
            result = a.description.toLower() < b.description.toLower();
            break;
        case SortByAmount:
            result = a.amount < b.amount;
            break;
        case SortByDate:
            result = a.date < b.date;
            break;
        default:
            result = a.date < b.date; // Default sort by date
            break;
        }

        return m_sortAscending ? result : !result;
    });
}

QJsonObject AwaitingTransactionModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_awaitingTransactions.size())
        return QJsonObject();

    const AwaitingTransaction &trans = m_awaitingTransactions.at(index);
    QJsonObject obj;
    obj["description"] = trans.description;
    obj["amount"] = trans.amount;
    obj["date"] = trans.date;
    return obj;
}

void AwaitingTransactionModel::entryFromJson(const QJsonObject &obj)
{
    AwaitingTransaction trans;
    trans.description = obj["description"].toString();
    trans.amount = obj["amount"].toDouble();
    trans.date = obj["date"].toString();
    m_awaitingTransactions.append(trans);
}

void AwaitingTransactionModel::addEntryToModel()
{
    // Not used in this implementation
}

void AwaitingTransactionModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_awaitingTransactions.removeAt(index);
    endRemoveRows();
}

void AwaitingTransactionModel::clearModel()
{
    m_awaitingTransactions.clear();
}
