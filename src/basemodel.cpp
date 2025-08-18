#include "basemodel.h"
#include <QDebug>

BaseModel::BaseModel(const QString &fileName, QObject *parent)
    : QAbstractListModel(parent)
    , m_fileName(fileName)
    , m_sortColumn(0)
    , m_sortAscending(true)
{
}

int BaseModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 0; // Override in derived classes
}

void BaseModel::removeEntry(int index)
{
    if (index < 0 || index >= rowCount())
        return;

    removeEntryFromModel(index);
    emit countChanged();
    saveToFile();
}

void BaseModel::loadFromFile()
{
    QString filePath = getDataFilePath();
    QFile file(filePath);

    if (!file.exists()) {
        qDebug() << "No data file found:" << filePath;
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open file for reading:" << filePath;
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << error.errorString();
        return;
    }

    beginResetModel();
    clearModel();

    QJsonArray array = doc.array();
    for (const QJsonValue &value : array) {
        QJsonObject obj = value.toObject();
        entryFromJson(obj);
    }

    // Sort after loading
    performSort();

    endResetModel();
    emit countChanged();

    qDebug() << "Loaded" << rowCount() << "entries from" << filePath;
}

void BaseModel::clear()
{
    if (rowCount() == 0)
        return;

    beginResetModel();
    clearModel();
    endResetModel();

    emit countChanged();
    saveToFile();
}

void BaseModel::sortBy(int column)
{
    if (m_sortColumn == column) {
        m_sortAscending = !m_sortAscending;
        emit sortAscendingChanged();
    } else {
        m_sortColumn = column;
        m_sortAscending = true;
        emit sortColumnChanged();
        emit sortAscendingChanged();
    }

    beginResetModel();
    performSort();
    endResetModel();
}

void BaseModel::saveToFile()
{
    QJsonArray array;

    for (int i = 0; i < rowCount(); ++i) {
        array.append(entryToJson(i));
    }

    QJsonDocument doc(array);

    QString filePath = getDataFilePath();
    QFileInfo fileInfo(filePath);
    QDir().mkpath(fileInfo.absolutePath());

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Could not open file for writing:" << filePath;
        return;
    }

    file.write(doc.toJson());
    file.close();

    qDebug() << "Saved" << rowCount() << "entries to" << filePath;
}

QString BaseModel::getDataFilePath() const
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    qDebug() << dataPath;
    return dataPath + "/" + m_fileName;
}
