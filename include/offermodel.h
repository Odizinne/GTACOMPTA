#ifndef OFFERMODEL_H
#define OFFERMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class OfferModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        PriceRole
    };
    Q_ENUM(Roles)

    enum SortColumns {
        SortByName = 0,
        SortByPrice = 1
    };
    Q_ENUM(SortColumns)

    explicit OfferModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Offer-specific methods
    Q_INVOKABLE void addOffer(const QString &name, int price);
    Q_INVOKABLE void updateOffer(int index, const QString &name, int price);
    Q_INVOKABLE QString getOfferName(int index) const;
    Q_INVOKABLE int getOfferPrice(int index) const;

signals:
    void priceDataChanged();

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

private:
    struct Offer {
        QString name;
        int price; // in cents
    };

    QList<Offer> m_offers;
};

#endif // OFFERMODEL_H
