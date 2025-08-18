#include "offermodel.h"
#include <algorithm>

OfferModel::OfferModel(QObject *parent)
    : BaseModel("offers.json", parent)
{
    m_sortColumn = SortByName; // Default sort by name
}

int OfferModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_offers.size();
}

QVariant OfferModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_offers.size())
        return QVariant();

    const Offer &offer = m_offers.at(index.row());

    switch (role) {
    case NameRole:
        return offer.name;
    case PriceRole:
        return offer.price;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> OfferModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PriceRole] = "price";
    return roles;
}

void OfferModel::addOffer(const QString &name, int price)
{
    beginInsertRows(QModelIndex(), m_offers.size(), m_offers.size());
    m_offers.append({name, price});
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void OfferModel::updateOffer(int index, const QString &name, int price)
{
    if (index < 0 || index >= m_offers.size())
        return;

    m_offers[index] = {name, price};

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

QString OfferModel::getOfferName(int index) const
{
    if (index < 0 || index >= m_offers.size())
        return "";

    return m_offers.at(index).name;
}

int OfferModel::getOfferPrice(int index) const
{
    if (index < 0 || index >= m_offers.size())
        return 0;

    return m_offers.at(index).price;
}

void OfferModel::performSort()
{
    std::sort(m_offers.begin(), m_offers.end(), [this](const Offer &a, const Offer &b) {
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

QJsonObject OfferModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_offers.size())
        return QJsonObject();

    const Offer &off = m_offers.at(index);
    QJsonObject obj;
    obj["name"] = off.name;
    obj["price"] = off.price;
    return obj;
}

void OfferModel::entryFromJson(const QJsonObject &obj)
{
    Offer off;
    off.name = obj["name"].toString();
    off.price = obj["price"].toInt();
    m_offers.append(off);
}

void OfferModel::addEntryToModel()
{
    // Not used in this implementation
}

void OfferModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_offers.removeAt(index);
    endRemoveRows();
}

void OfferModel::clearModel()
{
    m_offers.clear();
}
