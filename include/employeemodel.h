#ifndef EMPLOYEEMODEL_H
#define EMPLOYEEMODEL_H

#include "basemodel.h"

class EmployeeModel : public BaseModel
{
    Q_OBJECT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        EmailRole,
        PhoneRole,
        DepartmentRole,
        SalaryRole
    };

    explicit EmployeeModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Employee-specific methods
    Q_INVOKABLE void addEmployee(const QString &name, const QString &email,
                                 const QString &phone, const QString &department, double salary);
    Q_INVOKABLE void updateEmployee(int index, const QString &name, const QString &email,
                                    const QString &phone, const QString &department, double salary);

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;

private:
    struct Employee {
        QString name;
        QString email;
        QString phone;
        QString department;
        double salary;
    };

    QList<Employee> m_employees;
};

#endif // EMPLOYEEMODEL_H
