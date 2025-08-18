#ifndef SUPPLEMENTMODEL_H
#define SUPPLEMENTMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class SupplementModel : public BaseModel
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

    explicit SupplementModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Supplement-specific methods
    Q_INVOKABLE void addSupplement(const QString &name, int price);
    Q_INVOKABLE void updateSupplement(int index, const QString &name, int price);
    Q_INVOKABLE QString getSupplementName(int index) const;
    Q_INVOKABLE int getSupplementPrice(int index) const;

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

private:
    struct Supplement {
        QString name;
        int price; // in cents
    };

    QList<Supplement> m_supplements;
};

#endif // SUPPLEMENTMODEL_H
