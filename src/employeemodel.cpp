#include "employeemodel.h"

EmployeeModel::EmployeeModel(QObject *parent)
    : BaseModel("employees.json", parent)
{
}

int EmployeeModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
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
    case EmailRole:
        return employee.email;
    case PhoneRole:
        return employee.phone;
    case DepartmentRole:
        return employee.department;
    case SalaryRole:
        return employee.salary;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> EmployeeModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[EmailRole] = "email";
    roles[PhoneRole] = "phone";
    roles[DepartmentRole] = "department";
    roles[SalaryRole] = "salary";
    return roles;
}

void EmployeeModel::addEmployee(const QString &name, const QString &email,
                                const QString &phone, const QString &department, double salary)
{
    beginInsertRows(QModelIndex(), m_employees.size(), m_employees.size());
    m_employees.append({name, email, phone, department, salary});
    endInsertRows();

    emit countChanged();
    saveToFile();
}

void EmployeeModel::updateEmployee(int index, const QString &name, const QString &email,
                                   const QString &phone, const QString &department, double salary)
{
    if (index < 0 || index >= m_employees.size())
        return;

    m_employees[index] = {name, email, phone, department, salary};
    emit dataChanged(createIndex(index, 0), createIndex(index, 0));
    saveToFile();
}

QJsonObject EmployeeModel::entryToJson(int index) const
{
    if (index < 0 || index >= m_employees.size())
        return QJsonObject();

    const Employee &emp = m_employees.at(index);
    QJsonObject obj;
    obj["name"] = emp.name;
    obj["email"] = emp.email;
    obj["phone"] = emp.phone;
    obj["department"] = emp.department;
    obj["salary"] = emp.salary;
    return obj;
}

void EmployeeModel::entryFromJson(const QJsonObject &obj)
{
    Employee emp;
    emp.name = obj["name"].toString();
    emp.email = obj["email"].toString();
    emp.phone = obj["phone"].toString();
    emp.department = obj["department"].toString();
    emp.salary = obj["salary"].toDouble();
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
