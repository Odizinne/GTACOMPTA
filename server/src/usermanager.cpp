#include "usermanager.h"
#include <QDebug>
#include <QStandardPaths>
#include <QTextStream>

UserManager::UserManager(QObject *parent)
    : QObject(parent)
{
}

void UserManager::setDataDirectory(const QString &path)
{
    m_dataDirectory = path;
    loadUsers();
}

bool UserManager::authenticateUser(const QString &username, const QString &password)
{
    QString hashedPassword = hashPassword(password);

    for (const User &user : m_users) {
        if (user.name == username && user.passwordHash == hashedPassword) {
            qDebug() << "User" << username << "authenticated successfully";
            return true;
        }
    }

    qDebug() << "Authentication failed for user:" << username;
    return false;
}

bool UserManager::isUserReadOnly(const QString &username) const
{
    for (const User &user : m_users) {
        if (user.name == username) {
            return user.readonly;
        }
    }
    return true; // Default to readonly if user not found
}

bool UserManager::addUser(const QString &username, const QString &password, bool readonly)
{
    if (userExists(username)) {
        return false; // User already exists
    }

    User newUser;
    newUser.name = username;
    newUser.passwordHash = hashPassword(password);
    newUser.readonly = readonly;

    m_users.append(newUser);
    saveUsers();

    qDebug() << "User" << username << "added successfully" << (readonly ? "(read-only)" : "(full access)");
    return true;
}

bool UserManager::deleteUser(const QString &username)
{
    for (int i = 0; i < m_users.size(); ++i) {
        if (m_users[i].name == username) {
            m_users.removeAt(i);
            saveUsers();
            qDebug() << "User" << username << "deleted successfully";
            return true;
        }
    }

    qDebug() << "User" << username << "not found";
    return false;
}

bool UserManager::userExists(const QString &username) const
{
    for (const User &user : m_users) {
        if (user.name == username) {
            return true;
        }
    }
    return false;
}

void UserManager::listUsers() const
{
    QTextStream out(stdout);
    out << Qt::endl << "Registered users:" << Qt::endl;
    out << "=================" << Qt::endl;

    if (m_users.isEmpty()) {
        out << "No users found." << Qt::endl;
        return;
    }

    for (const User &user : m_users) {
        out << "  " << user.name << " - " << (user.readonly ? "read-only" : "full access") << Qt::endl;
    }
    out << Qt::endl;
}

void UserManager::loadUsers()
{
    QString filePath = getUsersFilePath();
    QFile file(filePath);

    if (!file.exists()) {
        qDebug() << "Users file doesn't exist, creating default users";
        createDefaultUsers();
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open users file:" << filePath;
        createDefaultUsers();
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error in users file:" << error.errorString();
        createDefaultUsers();
        return;
    }

    QJsonArray usersArray = doc.array();
    m_users.clear();

    for (const QJsonValue &value : usersArray) {
        QJsonObject userObj = value.toObject();
        User user;
        user.name = userObj["name"].toString();
        user.passwordHash = userObj["passwordHash"].toString();
        user.readonly = userObj["readonly"].toBool();
        m_users.append(user);
    }

    qDebug() << "Loaded" << m_users.size() << "users from file";
}

void UserManager::createDefaultUsers()
{
    m_users.clear();

    // Admin user
    User admin;
    admin.name = "admin";
    admin.passwordHash = hashPassword("shyvana0307");
    admin.readonly = false;
    m_users.append(admin);

    // Guest user
    User guest;
    guest.name = "guest";
    guest.passwordHash = hashPassword("guest");
    guest.readonly = true;
    m_users.append(guest);

    saveUsers();
    qDebug() << "Created default users";
}

void UserManager::saveUsers()
{
    QJsonArray usersArray;
    for (const User &user : m_users) {
        QJsonObject userObj;
        userObj["name"] = user.name;
        userObj["passwordHash"] = user.passwordHash;
        userObj["readonly"] = user.readonly;
        usersArray.append(userObj);
    }

    QJsonDocument doc(usersArray);
    QString filePath = getUsersFilePath();

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
        file.close();
        qDebug() << "Users saved to:" << filePath;
    } else {
        qWarning() << "Failed to save users file:" << filePath;
    }
}

QString UserManager::hashPassword(const QString &password) const
{
    QByteArray hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    return hash.toHex();
}

QString UserManager::getUsersFilePath() const
{
    return m_dataDirectory + "/users.json";
}
