#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QCryptographicHash>

class UserManager : public QObject
{
    Q_OBJECT

public:
    explicit UserManager(QObject *parent = nullptr);

    bool authenticateUser(const QString &username, const QString &password);
    bool isUserReadOnly(const QString &username) const;
    void loadUsers();
    void setDataDirectory(const QString &path);

    // Command-line user management
    bool addUser(const QString &username, const QString &password, bool readonly = false);
    bool deleteUser(const QString &username);
    bool userExists(const QString &username) const;
    void listUsers() const;

private:
    struct User {
        QString name;
        QString passwordHash;
        bool readonly;
    };

    void createDefaultUsers();
    QString hashPassword(const QString &password) const;
    QString getUsersFilePath() const;
    void saveUsers();

    QList<User> m_users;
    QString m_dataDirectory;
};

#endif // USERMANAGER_H
