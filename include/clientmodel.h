#ifndef CLIENTMODEL_H
#define CLIENTMODEL_H
#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class ClientModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        BusinessTypeRole = Qt::UserRole + 1,
        NameRole,
        OfferRole,
        PriceRole,
        SupplementsRole,
        ChestIDRole,
        DiscountRole,
        PhoneNumberRole,
        CommentRole
    };

    enum BusinessType {
        Business = 0,
        Consumer = 1
    };
    Q_ENUM(BusinessType)

    enum Offer {
        Bronze = 0,
        Silver = 1,
        Gold = 2
    };
    Q_ENUM(Offer)

    enum SortColumns {
        SortByBusinessType = 0,
        SortByName = 1,
        SortByOffer = 2,
        SortByPrice = 3,
        SortByChestID = 5,
        SortByDiscount = 6,
        SortByPhone = 7,
        SortByComment = 8
    };
    Q_ENUM(SortColumns)

    explicit ClientModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void addClient(int businessType, const QString &name, int offer, int price,
                               const QList<int> &supplements,
                               int chestID, int discount, const QString &phoneNumber,
                               const QString &comment);
    Q_INVOKABLE void updateClient(int index, int businessType, const QString &name, int offer, int price,
                                  const QList<int> &supplements,
                                  int chestID, int discount, const QString &phoneNumber,
                                  const QString &comment);
    //Q_INVOKABLE int calculatePrice(int offer, const QList<int> &supplements, int discount);
    Q_INVOKABLE void checkout(int clientIndex);
    Q_INVOKABLE int getSupplementCount() const;
    Q_INVOKABLE QString getSupplementName(int id) const;
    Q_INVOKABLE double getSupplementPriceDisplay(int id) const;

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

signals:
    void checkoutCompleted(const QString &description, double amount);

private:
    static const int BRONZE_BASE_PRICE = 1000;
    static const int SILVER_BASE_PRICE = 2000;
    static const int GOLD_BASE_PRICE = 3000;
    struct Client {
        BusinessType businessType;
        QString name;
        Offer offer;
        int price;
        QList<int> supplements;
        int chestID;
        int discount;
        QString phoneNumber;
        QString comment;
    };
    QList<Client> m_clients;
    int getSupplementPrice(int supplementId) const;
};
#endif // CLIENTMODEL_H
