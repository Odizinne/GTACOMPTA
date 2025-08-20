#include "companysummarymodel.h"
#include <QDebug>

CompanySummaryModel::CompanySummaryModel(QObject *parent)
    : BaseModel("company_summary.json", parent)
    , m_money(0)
    , m_companyName("")
{
}

int CompanySummaryModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 1;
}

QVariant CompanySummaryModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(index)
    Q_UNUSED(role)
    return QVariant();
}

QHash<int, QByteArray> CompanySummaryModel::roleNames() const
{
    return QHash<int, QByteArray>();
}

int CompanySummaryModel::money() const
{
    return m_money;
}

void CompanySummaryModel::setMoney(int money)
{
    if (m_money != money) {
        m_money = money;
        emit moneyChanged();
        saveToFile();
    }
}

QString CompanySummaryModel::companyName() const
{
    return m_companyName;
}

void CompanySummaryModel::setCompanyName(const QString &name)
{
    if (m_companyName != name) {
        m_companyName = name;
        emit companyNameChanged();
        saveToFile();
    }
}

void CompanySummaryModel::addToMoney(int amount)
{
    setMoney(m_money + amount);
}

void CompanySummaryModel::subtractFromMoney(int amount)
{
    setMoney(m_money - amount);
}

QJsonObject CompanySummaryModel::entryToJson(int index) const
{
    Q_UNUSED(index)
    QJsonObject obj;
    obj["money"] = m_money;
    obj["companyName"] = m_companyName;
    return obj;
}

void CompanySummaryModel::entryFromJson(const QJsonObject &obj)
{
    m_money = obj["money"].toInt(0);
    m_companyName = obj["companyName"].toString("");

    emit moneyChanged();
    emit companyNameChanged();
}

void CompanySummaryModel::addEntryToModel()
{
}

void CompanySummaryModel::removeEntryFromModel(int index)
{
    Q_UNUSED(index)
}

void CompanySummaryModel::clearModel()
{
    m_money = 0;
    m_companyName = "";
    emit moneyChanged();
    emit companyNameChanged();
}

void CompanySummaryModel::performSort()
{
}
