#ifndef BASEMODEL_H
#define BASEMODEL_H

#include <QAbstractListModel>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QtQml/qqmlregistration.h>

class DataManager;
class RemoteDatabaseManager;

class BaseModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int sortColumn READ sortColumn NOTIFY sortColumnChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending NOTIFY sortAscendingChanged)

    friend class DataManager;

public:
    explicit BaseModel(const QString &fileName, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Q_INVOKABLE void removeEntry(int index);
    Q_INVOKABLE void loadFromFile(bool remote);
    Q_INVOKABLE void clear();
    Q_INVOKABLE virtual void sortBy(int column);

    int count() const { return rowCount(); }
    int sortColumn() const { return m_sortColumn; }
    bool sortAscending() const { return m_sortAscending; }

signals:
    void countChanged();
    void sortColumnChanged();
    void sortAscendingChanged();

protected:
    virtual QJsonObject entryToJson(int index) const = 0;
    virtual void entryFromJson(const QJsonObject &obj) = 0;
    virtual void addEntryToModel() = 0;
    virtual void removeEntryFromModel(int index) = 0;
    virtual void clearModel() = 0;
    virtual void performSort() = 0;

    void saveToFile();
    void loadFromLocal();        // Added this method
    void loadFromRemote();       // Added this method
    void saveToLocal(const QJsonArray &array);  // Added this method
    QString getDataFilePath() const;

    int m_sortColumn;
    bool m_sortAscending;

private slots:
    void onRemoteDataLoaded(const QString &collection, const QJsonObject &data);  // Added this slot
    void onRemoteDataSaved(const QString &collection, bool success);  // Added this slot

private:
    void ensureRemoteConnection();
    QString m_fileName;
    bool m_isLoading;  // Added this member variable
};

#endif // BASEMODEL_H
