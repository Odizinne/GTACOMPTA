#include "filterproxymodel.h"
#include "employeemodel.h"
#include "transactionmodel.h"
#include "awaitingtransactionmodel.h"
#include "clientmodel.h"

FilterProxyModel::FilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

QString FilterProxyModel::filterText() const
{
    return m_filterText;
}

void FilterProxyModel::setFilterText(const QString &text)
{
    if (m_filterText != text) {
        m_filterText = text;
        invalidateFilter();
        emit filterTextChanged();
    }
}

void FilterProxyModel::setSourceModel(QAbstractItemModel *model)
{
    QSortFilterProxyModel::setSourceModel(model);
    emit sourceModelChanged();
}

bool FilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_filterText.isEmpty()) {
        return true;
    }

    QAbstractItemModel *model = sourceModel();
    if (!model) {
        return false;
    }

    QModelIndex index = model->index(sourceRow, 0, sourceParent);

    // Check if this is an EmployeeModel
    if (qobject_cast<EmployeeModel*>(model)) {
        QString name = model->data(index, EmployeeModel::NameRole).toString();
        QString phone = model->data(index, EmployeeModel::PhoneRole).toString();
        QString role = model->data(index, EmployeeModel::RoleRole).toString();
        QString salary = QString::number(model->data(index, EmployeeModel::SalaryRole).toInt());
        QString addedDate = model->data(index, EmployeeModel::AddedDateRole).toString();
        QString comment = model->data(index, EmployeeModel::CommentRole).toString();

        return matchesFilter(name) || matchesFilter(phone) || matchesFilter(role) ||
               matchesFilter(salary) || matchesFilter(addedDate) || matchesFilter(comment);
    }

    // Check if this is a TransactionModel
    if (qobject_cast<TransactionModel*>(model)) {
        QString description = model->data(index, TransactionModel::DescriptionRole).toString();
        QString amount = QString::number(model->data(index, TransactionModel::AmountRole).toDouble());
        QString date = model->data(index, TransactionModel::DateRole).toString();

        return matchesFilter(description) || matchesFilter(amount) || matchesFilter(date);
    }

    // Check if this is an AwaitingTransactionModel
    if (qobject_cast<AwaitingTransactionModel*>(model)) {
        QString description = model->data(index, AwaitingTransactionModel::DescriptionRole).toString();
        QString amount = QString::number(model->data(index, AwaitingTransactionModel::AmountRole).toDouble());
        QString date = model->data(index, AwaitingTransactionModel::DateRole).toString();

        return matchesFilter(description) || matchesFilter(amount) || matchesFilter(date);
    }

    // Check if this is a ClientModel
    if (qobject_cast<ClientModel*>(model)) {
        QString name = model->data(index, ClientModel::NameRole).toString();
        QString phone = model->data(index, ClientModel::PhoneNumberRole).toString();
        QString paymentDate = model->data(index, ClientModel::PaymentDateRole).toString();
        QString comment = model->data(index, ClientModel::CommentRole).toString();

        // Format price as display string
        double priceValue = model->data(index, ClientModel::PriceRole).toDouble();
        QString price = QString::number(priceValue / 100.0, 'f', 2);

        // Format business type
        int businessTypeValue = model->data(index, ClientModel::BusinessTypeRole).toInt();
        QString businessType = (businessTypeValue == 0) ? "Pro" : "Part";

        return matchesFilter(name) || matchesFilter(phone) || matchesFilter(comment) ||
               matchesFilter(price) || matchesFilter(businessType);
    }

    return false;
}

bool FilterProxyModel::matchesFilter(const QString &text) const
{
    return text.contains(m_filterText, Qt::CaseInsensitive);
}
