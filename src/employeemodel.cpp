#include "employeemodel.h"
#include <algorithm>

EmployeeModel::EmployeeModel(QObject *parent)
    : BaseModel("employees.json", parent)
{
    m_sortColumn = SortByName; // Default sort by name
}

int EmployeeModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_employees.size();
}

QVariant EmployeeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_employees.size())
        return QVariant();

    const Employee &employee = m_employees.at(index.row());

    switch (role) {
    case NameRole:
        return employee.name;
    case PhoneRole:
        return employee.phone;
    case RoleRole:
        return employee.role;
    case SalaryRole:
        return employee.salary;
    case AddedDateRole:
        return employee.addedDate;
    case CommentRole:
        return employee.comment;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> EmployeeModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PhoneRole] = "phone";
    roles[RoleRole] = "role";
    roles[SalaryRole] = "salary";
    roles[AddedDateRole] = "addedDate";
    roles[CommentRole] = "comment";
    return roles;
}

void EmployeeModel::addEmployee(const QString &name, const QString &phone,
                                const QString &role, int salary, const QString &addedDate, const QString &comment)
{
    beginInsertRows(QModelIndex(), m_employees.size(), m_employees.size());
    m_employees.append({name, phone, role, salary, addedDate, comment});
    endInsertRows();

    // Sort after adding
    beginResetModel();
    performSort();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void EmployeeModel::updateEmployee(int index, const QString &name, const QString &phone,
                                   const QString &role, int salary, const QString &addedDate, const QString &comment)
{
    if (index < 0 || index >= m_employees.size())
        return;

    m_employees[index] = {name, phone, role, salary, addedDate, comment};

    // Resort after updating
    beginResetModel();
    performSort();
    endResetModel();

    saveToFile();
}

void EmployeeModel::payEmployee(int employeeIndex)
{
    if (employeeIndex < 0 || employeeIndex >= m_employees.size())
        return;

    const Employee &employee = m_employees.at(employeeIndex);
    QString description = QString("Salary payment for %1").arg(employee.name);

    emit paymentCompleted(description, -employee.salary);
}

void EmployeeModel::performSort()
{
    std::sort(m_employees.begin(), m_employees.end(), [this](const Employee &a, const Employee &b) {
        bool result = false;

        switch (m_sortColumn) {
        case SortByName:
            result = a.name.toLower() < b.name.toLower();
            break;
        case SortByPhone:
            result = a.phone < b.phone;
            break;
        case SortByRole:
            result = a.role.toLower() < b.role.toLower();
            break;
        case SortBySalary:
            result = a.salary < b.salary;
            break;
        case SortByAddedDate:
            result = a.addedDate < b.addedDate;
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

QJsonObject EmployeeModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_employees.size())
        return QJsonObject();

    const Employee &emp = m_employees.at(index);
    QJsonObject obj;
    obj["name"] = emp.name;
    obj["phone"] = emp.phone;
    obj["role"] = emp.role;
    obj["salary"] = emp.salary;
    obj["addedDate"] = emp.addedDate;
    obj["comment"] = emp.comment;
    return obj;
}

void EmployeeModel::entryFromJson(const QJsonObject &obj)
{
    Employee emp;
    emp.name = obj["name"].toString();
    emp.phone = obj["phone"].toString();
    emp.role = obj["role"].toString();
    emp.salary = obj["salary"].toInt();
    emp.addedDate = obj["addedDate"].toString();
    emp.comment = obj["comment"].toString();
    m_employees.append(emp);
}

void EmployeeModel::addEntryToModel()
{
    // Not used in this implementation
}

void EmployeeModel::removeEntryFromModel(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_employees.removeAt(index);
    endRemoveRows();
}

void EmployeeModel::clearModel()
{
    m_employees.clear();
}
