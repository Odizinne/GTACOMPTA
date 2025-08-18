#ifndef EMPLOYEEMODEL_H
#define EMPLOYEEMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class EmployeeModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        PhoneRole,
        RoleRole,
        SalaryRole,
        AddedDateRole,
        CommentRole
    };

    enum SortColumns {
        SortByName = 0,
        SortByPhone = 1,
        SortByRole = 2,
        SortBySalary = 3,
        SortByAddedDate = 4,
        SortByComment = 5
    };
    Q_ENUM(SortColumns)

    explicit EmployeeModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void addEmployee(const QString &name, const QString &phone,
                                 const QString &role, int salary, const QString &addedDate, const QString &comment);
    Q_INVOKABLE void updateEmployee(int index, const QString &name, const QString &phone,
                                    const QString &role, int salary, const QString &addedDate, const QString &comment);
    Q_INVOKABLE void payEmployee(int employeeIndex);

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

signals:
    void paymentCompleted(const QString &description, double amount);

private:
    struct Employee {
        QString name;
        QString phone;
        QString role;
        int salary;
        QString addedDate;
        QString comment;
    };

    QList<Employee> m_employees;
};

#endif // EMPLOYEEMODEL_H
