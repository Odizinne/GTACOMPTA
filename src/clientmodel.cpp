#include "clientmodel.h"
#include <QJsonArray>
#include <algorithm>

ClientModel::ClientModel(QObject *parent)
    : BaseModel("clients.json", parent)
    , m_offerModel(nullptr)
    , m_supplementModel(nullptr)
{
    m_sortColumn = SortByName; // Default sort by name
}

void ClientModel::setOfferModel(OfferModel *model)
{
    m_offerModel = model;
}

void ClientModel::setSupplementModel(SupplementModel *model)
{
    m_supplementModel = model;
}

int ClientModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_clients.size();
}

QVariant ClientModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_clients.size())
        return QVariant();

    const Client &client = m_clients.at(index.row());

    switch (role) {
    case BusinessTypeRole:
        return static_cast<int>(client.businessType);
    case NameRole:
        return client.name;
    case OfferRole:
        return static_cast<int>(client.offer);
    case PriceRole:
        return client.price;
    case SupplementsRole:
        return QVariant::fromValue(client.supplements);
    case DiscountRole:
        return client.discount;
    case PhoneNumberRole:
        return client.phoneNumber;
    case CommentRole:
        return client.comment;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ClientModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[BusinessTypeRole] = "businessType";
    roles[NameRole] = "name";
    roles[OfferRole] = "offer";
    roles[PriceRole] = "price";
    roles[SupplementsRole] = "supplements";
    roles[DiscountRole] = "discount";
    roles[PhoneNumberRole] = "phoneNumber";
    roles[CommentRole] = "comment";
    return roles;
}

void ClientModel::addClient(int businessType, const QString &name, int offer, int price,
                            const QList<int> &supplements, int discount, const QString &phoneNumber,
                            const QString &comment)
{
    beginInsertRows(QModelIndex(), m_clients.size(), m_clients.size());
    Client client;
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);
    client.price = price;

    // Convert list to map - for backward compatibility, assume quantity 1
    for (int suppId : supplements) {
        client.supplements[suppId] = 1;
    }

    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;
    m_clients.append(client);
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void ClientModel::updateClient(int index, int businessType, const QString &name, int offer, int price,
                               const QList<int> &supplements, int discount, const QString &phoneNumber,
                               const QString &comment)
{
    if (index < 0 || index >= m_clients.size())
        return;

    Client &client = m_clients[index];
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);
    client.price = price;

    // Convert list to map - for backward compatibility, assume quantity 1
    client.supplements.clear();
    for (int suppId : supplements) {
        client.supplements[suppId] = 1;
    }

    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

QJsonObject ClientModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_clients.size())
        return QJsonObject();

    const Client &client = m_clients.at(index);
    QJsonObject obj;
    obj["businessType"] = static_cast<int>(client.businessType);
    obj["name"] = client.name;
    obj["offer"] = static_cast<int>(client.offer);
    obj["price"] = client.price;

    QJsonObject supplementsObj;
    for (auto it = client.supplements.begin(); it != client.supplements.end(); ++it) {
        supplementsObj[QString::number(it.key())] = it.value();
    }
    obj["supplements"] = supplementsObj;

    obj["discount"] = client.discount;
    obj["phoneNumber"] = client.phoneNumber;
    obj["comment"] = client.comment;
    return obj;
}

void ClientModel::entryFromJson(const QJsonObject &obj)
{
    Client client;
    client.businessType = static_cast<BusinessType>(obj["businessType"].toInt());
    client.name = obj["name"].toString();
    client.offer = static_cast<Offer>(obj["offer"].toInt(0));
    client.price = obj["price"].toInt();

    // Handle both old format (array) and new format (object)
    if (obj["supplements"].isArray()) {
        // Old format - convert to new format with quantity 1
        QJsonArray supplementsArray = obj["supplements"].toArray();
        for (const QJsonValue &value : supplementsArray) {
            client.supplements[value.toInt()] = 1;
        }
    } else if (obj["supplements"].isObject()) {
        // New format
        QJsonObject supplementsObj = obj["supplements"].toObject();
        for (auto it = supplementsObj.begin(); it != supplementsObj.end(); ++it) {
            client.supplements[it.key().toInt()] = it.value().toInt();
        }
    }

    client.discount = obj["discount"].toInt();
    client.phoneNumber = obj["phoneNumber"].toString();
    client.comment = obj["comment"].toString();
    m_clients.append(client);
}

void ClientModel::performSort()
{
    std::sort(m_clients.begin(), m_clients.end(), [this](const Client &a, const Client &b) {
        bool result = false;

        switch (m_sortColumn) {
        case SortByBusinessType:
            result = a.businessType < b.businessType;
            break;
        case SortByName:
            result = a.name.toLower() < b.name.toLower();
            break;
        case SortByOffer:
            result = a.offer < b.offer;
            break;
        case SortByPrice:
            result = a.price < b.price;
            break;
        case SortByDiscount:
            result = a.discount < b.discount;
            break;
        case SortByPhone:
            result = a.phoneNumber.toLower() < b.phoneNumber.toLower();
            break;
        case SortByComment:
            result = a.comment.toLower() < b.comment.toLower();
            break;
        default:
            result = a.name.toLower() < b.name.toLower();
            break;
        }

        return m_sortAscending ? result : !result;
    });
}

void ClientModel::addEntryToModel()
{
    // Not used in this implementation
}

void ClientModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_clients.removeAt(index);
    endRemoveRows();
}

void ClientModel::clearModel()
{
    m_clients.clear();
}

int ClientModel::getSupplementCount() const
{
    return 9;
}

QString ClientModel::getSupplementName(int id) const
{
    switch (id) {
    case 1: return "Anti-Natural Spectra-Block Paint";
    case 2: return "Pure-Human Lock Biometric";
    case 3: return "Eternal Shield Anti-Rust Coating";
    case 4: return "Air-Pure Pro Ventilation System";
    case 5: return "Natural-Detector 3000 Alarm";
    case 6: return "Essence-Dry Dehumidifier";
    case 7: return "Psi-Resistant Shielding";
    case 8: return "Decontam-Plus Cleaning Service";
    case 9: return "24/7 Emergency Nexus Access";
    default: return "";
    }
}

double ClientModel::getSupplementPriceDisplay(int id) const
{
    if (!m_supplementModel) {
        return 0.0;
    }

    if (id >= 0 && id < m_supplementModel->rowCount()) {
        return m_supplementModel->getSupplementPrice(id);
    }

    return 0.0;
}

void ClientModel::checkout(int clientIndex)
{
    if (clientIndex < 0 || clientIndex >= m_clients.size())
        return;

    const Client &client = m_clients.at(clientIndex);
    QString description = QString("Checkout for %1").arg(client.name);

    emit checkoutCompleted(description, client.price);
}

QVariantMap ClientModel::getSupplementQuantities(int clientIndex) const
{
    QVariantMap result;
    if (clientIndex < 0 || clientIndex >= m_clients.size())
        return result;

    const Client &client = m_clients.at(clientIndex);
    for (auto it = client.supplements.begin(); it != client.supplements.end(); ++it) {
        result[QString::number(it.key())] = it.value();
    }
    return result;
}

void ClientModel::addClientWithQuantities(int businessType, const QString &name, int offer, int price,
                                          const QVariantMap &supplementQuantities, int discount,
                                          const QString &phoneNumber, const QString &comment)
{
    beginInsertRows(QModelIndex(), m_clients.size(), m_clients.size());
    Client client;
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);
    client.price = price;

    // Convert QVariantMap to QMap<int, int>
    for (auto it = supplementQuantities.begin(); it != supplementQuantities.end(); ++it) {
        int suppId = it.key().toInt();
        int quantity = it.value().toInt();
        if (quantity > 0) {
            client.supplements[suppId] = quantity;
        }
    }

    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;
    m_clients.append(client);
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void ClientModel::updateClientWithQuantities(int index, int businessType, const QString &name, int offer, int price,
                                             const QVariantMap &supplementQuantities, int discount,
                                             const QString &phoneNumber, const QString &comment)
{
    if (index < 0 || index >= m_clients.size())
        return;

    Client &client = m_clients[index];
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);
    client.price = price;

    // Convert QVariantMap to QMap<int, int>
    client.supplements.clear();
    for (auto it = supplementQuantities.begin(); it != supplementQuantities.end(); ++it) {
        int suppId = it.key().toInt();
        int quantity = it.value().toInt();
        if (quantity > 0) {
            client.supplements[suppId] = quantity;
        }
    }

    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

void ClientModel::recalculateAllPrices()
{
    if (!m_offerModel || !m_supplementModel) {
        qWarning() << "Cannot recalculate prices: models not set";
        return;
    }

    for (int i = 0; i < m_clients.size(); ++i) {
        Client &client = m_clients[i];

        // Get base price from actual offer model
        int basePrice = 0;
        if (client.offer >= 0 && client.offer < m_offerModel->rowCount()) {
            basePrice = m_offerModel->getOfferPrice(client.offer);
        }

        // Get supplement prices from actual supplement model
        int supplementsTotal = 0;
        for (auto it = client.supplements.begin(); it != client.supplements.end(); ++it) {
            int suppId = it.key();
            int quantity = it.value();
            if (suppId >= 0 && suppId < m_supplementModel->rowCount()) {
                supplementsTotal += m_supplementModel->getSupplementPrice(suppId) * quantity;
            }
        }

        int totalBeforeDiscount = basePrice + supplementsTotal;
        int newPrice = totalBeforeDiscount * (100 - client.discount) / 100;

        if (client.price != newPrice) {
            client.price = newPrice;
            QModelIndex idx = index(i, 0);
            emit dataChanged(idx, idx, {PriceRole});
        }
    }

    saveToFile();
}
