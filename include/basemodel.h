#ifndef BASEMODEL_H
#define BASEMODEL_H

#include <QAbstractListModel>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QtQml/qqmlregistration.h>

class BaseModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit BaseModel(const QString &fileName, QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    // Common methods
    Q_INVOKABLE void removeEntry(int index);
    Q_INVOKABLE void loadFromFile();
    Q_INVOKABLE void clear();

    int count() const { return rowCount(); }

signals:
    void countChanged();

protected:
    virtual QJsonObject entryToJson(int index) const = 0;
    virtual void entryFromJson(const QJsonObject &obj) = 0;
    virtual void addEntryToModel() = 0;
    virtual void removeEntryFromModel(int index) = 0;
    virtual void clearModel() = 0;

    void saveToFile();
    QString getDataFilePath() const;

private:
    QString m_fileName;
};

#endif // BASEMODEL_H
