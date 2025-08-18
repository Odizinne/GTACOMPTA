#include "supplementmodel.h"
#include <algorithm>

SupplementModel::SupplementModel(QObject *parent)
    : BaseModel("supplements.json", parent)
{
    m_sortColumn = SortByName; // Default sort by name
}

int SupplementModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_supplements.size();
}

QVariant SupplementModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_supplements.size())
        return QVariant();

    const Supplement &supplement = m_supplements.at(index.row());

    switch (role) {
    case NameRole:
        return supplement.name;
    case PriceRole:
        return supplement.price;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> SupplementModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PriceRole] = "price";
    return roles;
}

void SupplementModel::addSupplement(const QString &name, int price)
{
    beginInsertRows(QModelIndex(), m_supplements.size(), m_supplements.size());
    m_supplements.append({name, price});
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void SupplementModel::updateSupplement(int index, const QString &name, int price)
{
    if (index < 0 || index >= m_supplements.size())
        return;

    m_supplements[index] = {name, price};

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

QString SupplementModel::getSupplementName(int index) const
{
    if (index < 0 || index >= m_supplements.size())
        return "";

    return m_supplements.at(index).name;
}

int SupplementModel::getSupplementPrice(int index) const
{
    if (index < 0 || index >= m_supplements.size())
        return 0;

    return m_supplements.at(index).price;
}

void SupplementModel::performSort()
{
    std::sort(m_supplements.begin(), m_supplements.end(), [this](const Supplement &a, const Supplement &b) {
        bool result = false;

        switch (m_sortColumn) {
        case SortByName:
            result = a.name.toLower() < b.name.toLower();
            break;
        case SortByPrice:
            result = a.price < b.price;
            break;
        default:
            result = a.name.toLower() < b.name.toLower();
            break;
        }

        return m_sortAscending ? result : !result;
    });
}

QJsonObject SupplementModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_supplements.size())
        return QJsonObject();

    const Supplement &supp = m_supplements.at(index);
    QJsonObject obj;
    obj["name"] = supp.name;
    obj["price"] = supp.price;
    return obj;
}

void SupplementModel::entryFromJson(const QJsonObject &obj)
{
    Supplement supp;
    supp.name = obj["name"].toString();
    supp.price = obj["price"].toInt();
    m_supplements.append(supp);
}

void SupplementModel::addEntryToModel()
{
    // Not used in this implementation
}

void SupplementModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_supplements.removeAt(index);
    endRemoveRows();
}

void SupplementModel::clearModel()
{
    m_supplements.clear();
}
