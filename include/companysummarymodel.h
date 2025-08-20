#ifndef COMPANYSUMMARYMODEL_H
#define COMPANYSUMMARYMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class CompanySummaryModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int money READ money NOTIFY moneyChanged)  // READ-ONLY
    Q_PROPERTY(QString companyName READ companyName WRITE setCompanyName NOTIFY companyNameChanged)

public:
    explicit CompanySummaryModel(QObject *parent = nullptr);

    // QAbstractListModel interface (required by BaseModel)
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Company summary properties
    int money() const;
    QString companyName() const;
    void setCompanyName(const QString &name);

    // Money manipulation (only for internal use by transactions)
    Q_INVOKABLE void addToMoney(int amount);
    Q_INVOKABLE void subtractFromMoney(int amount);

signals:
    void moneyChanged();
    void companyNameChanged();

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

private:
    void setMoney(int money);  // Private setter

    int m_money;
    QString m_companyName;
};

#endif // COMPANYSUMMARYMODEL_H
