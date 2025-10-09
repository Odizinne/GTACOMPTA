#ifndef CLIENTMODEL_H
#define CLIENTMODEL_H
#include "basemodel.h"
#include "offermodel.h"
#include "supplementmodel.h"
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
        DiscountRole,
        PhoneNumberRole,
        PaymentDateRole,
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
        SortByDiscount = 5,
        SortByPhone = 6,
        SortByPaymentDate = 7,
        SortByComment = 8
    };
    Q_ENUM(SortColumns)

    explicit ClientModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void addClient(int businessType, const QString &name, int offer, int price,
                               const QList<int> &supplements, int discount, const QString &phoneNumber, const QString &paymentDate,
                               const QString &comment);
    Q_INVOKABLE void updateClient(int index, int businessType, const QString &name, int offer, int price,
                                  const QList<int> &supplements, int discount, const QString &phoneNumber, const QString &paymentDate,
                                  const QString &comment);
    Q_INVOKABLE void checkout(int clientIndex);
    Q_INVOKABLE int getSupplementCount() const;
    Q_INVOKABLE QString getSupplementName(int id) const;
    Q_INVOKABLE double getSupplementPriceDisplay(int id) const;
    Q_INVOKABLE QVariantMap getSupplementQuantities(int clientIndex) const;
    Q_INVOKABLE void addClientWithQuantities(int businessType, const QString &name, int offer, int price,
                                             const QVariantMap &supplementQuantities, int discount,
                                             const QString &phoneNumber, const QString &paymentDate, const QString &comment);
    Q_INVOKABLE void updateClientWithQuantities(int index, int businessType, const QString &name, int offer, int price,
                                                const QVariantMap &supplementQuantities, int discount,
                                                const QString &phoneNumber, const QString &paymentDate, const QString &comment);
    Q_INVOKABLE void setOfferModel(OfferModel *model);
    Q_INVOKABLE void setSupplementModel(SupplementModel *model);
    Q_INVOKABLE void recalculateAllPrices();
    Q_INVOKABLE void updateComment(int row, const QString &comment);

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
    struct Client {
        BusinessType businessType;
        QString name;
        Offer offer;
        int price;
        QMap<int, int> supplements;
        int discount;
        QString phoneNumber;
        QString paymentDate;
        QString comment;
    };
    QList<Client> m_clients;

    OfferModel *m_offerModel;
    SupplementModel *m_supplementModel;
};
#endif // CLIENTMODEL_H
