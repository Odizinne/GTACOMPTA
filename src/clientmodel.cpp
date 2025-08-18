#include "clientmodel.h"
#include <QJsonArray>

ClientModel::ClientModel(QObject *parent)
    : BaseModel("clients.json", parent)
{
}

int ClientModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
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
    case OfferRole:  // Added offer case
        return static_cast<int>(client.offer);
    case PriceRole:
        return client.price;
    case SupplementsRole:
        return QVariant::fromValue(client.supplements);
    case ChestIDRole:
        return client.chestID;
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
    roles[OfferRole] = "offer";  // Added offer role name
    roles[PriceRole] = "price";
    roles[SupplementsRole] = "supplements";
    roles[ChestIDRole] = "chestID";
    roles[DiscountRole] = "discount";
    roles[PhoneNumberRole] = "phoneNumber";
    roles[CommentRole] = "comment";
    return roles;
}

void ClientModel::addClient(int businessType, const QString &name, int offer, int price,
                            const QList<int> &supplements,
                            int chestID, int discount, const QString &phoneNumber,
                            const QString &comment)
{
    beginInsertRows(QModelIndex(), m_clients.size(), m_clients.size());
    Client client;
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);  // Added offer assignment
    client.price = price;
    client.supplements = supplements;
    client.chestID = chestID;
    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;
    m_clients.append(client);
    endInsertRows();

    emit countChanged();
    saveToFile();
}

void ClientModel::updateClient(int index, int businessType, const QString &name, int offer, int price,
                               const QList<int> &supplements,
                               int chestID, int discount, const QString &phoneNumber,
                               const QString &comment)
{
    if (index < 0 || index >= m_clients.size())
        return;

    Client &client = m_clients[index];
    client.businessType = static_cast<BusinessType>(businessType);
    client.name = name;
    client.offer = static_cast<Offer>(offer);  // Added offer assignment
    client.price = price;
    client.supplements = supplements;
    client.chestID = chestID;
    client.discount = discount;
    client.phoneNumber = phoneNumber;
    client.comment = comment;

    emit dataChanged(createIndex(index, 0), createIndex(index, 0));
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
    obj["offer"] = static_cast<int>(client.offer);  // Added offer to JSON
    obj["price"] = client.price;

    QJsonArray supplementsArray;
    for (int supplement : client.supplements) {
        supplementsArray.append(supplement);
    }
    obj["supplements"] = supplementsArray;

    obj["chestID"] = client.chestID;
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
    client.offer = static_cast<Offer>(obj["offer"].toInt(0));  // Added offer from JSON with default 0 (Bronze)
    client.price = obj["price"].toInt();

    QJsonArray supplementsArray = obj["supplements"].toArray();
    for (const QJsonValue &value : supplementsArray) {
        client.supplements.append(value.toInt());
    }

    client.chestID = obj["chestID"].toInt();
    client.discount = obj["discount"].toInt();
    client.phoneNumber = obj["phoneNumber"].toString();
    client.comment = obj["comment"].toString();
    m_clients.append(client);
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

int ClientModel::calculatePrice(int offer, const QList<int> &supplements, int discount)
{
    // Base price from offer
    int basePrice = 0;
    switch (offer) {
    case Bronze: basePrice = BRONZE_BASE_PRICE; break;
    case Silver: basePrice = SILVER_BASE_PRICE; break;
    case Gold: basePrice = GOLD_BASE_PRICE; break;
    default: basePrice = BRONZE_BASE_PRICE; break;
    }

    // Calculate supplements total (you'll need to get supplement prices from your model)
    int supplementsTotal = 0;
    for (int supplementId : supplements) {
        // This assumes you have a way to get supplement price by ID
        // You might need to modify this based on how you store supplement prices
        supplementsTotal += getSupplementPrice(supplementId);
    }

    // Calculate total before discount
    int totalBeforeDiscount = basePrice + supplementsTotal;

    // Apply discount
    int finalPrice = totalBeforeDiscount * (100 - discount) / 100;

    return finalPrice;
}

// Helper method to get supplement price (you'll need to implement this)
int ClientModel::getSupplementPrice(int supplementId)
{
    // This is a simple mapping - you might want to make this more sophisticated
    switch (supplementId) {
    case 1: return 250; // Extra Cheese $2.50 as cents
    case 2: return 300; // Bacon $3.00 as cents
    case 3: return 175; // Mushrooms $1.75 as cents
    case 4: return 225; // Pepperoni $2.25 as cents
    case 5: return 150; // Olives $1.50 as cents
    case 6: return 125; // Tomatoes $1.25 as cents
    default: return 0;
    }
}

void ClientModel::checkout(int clientIndex)
{
    if (clientIndex < 0 || clientIndex >= m_clients.size())
        return;

    const Client &client = m_clients.at(clientIndex);
    QString description = QString("Checkout for %1").arg(client.name);

    emit checkoutCompleted(description, client.price);
}
