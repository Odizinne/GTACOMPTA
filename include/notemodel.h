#ifndef NOTEMODEL_H
#define NOTEMODEL_H

#include "basemodel.h"
#include <QtQml/qqmlregistration.h>

class NoteModel : public BaseModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString content READ content WRITE setContent NOTIFY contentChanged)

public:
    explicit NoteModel(QObject *parent = nullptr);

    // QAbstractListModel interface (required by BaseModel)
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Note properties
    QString content() const;
    void setContent(const QString &content);

signals:
    void contentChanged();

protected:
    QJsonObject entryToJson(int index) const override;
    void entryFromJson(const QJsonObject &obj) override;
    void addEntryToModel() override;
    void removeEntryFromModel(int index) override;
    void clearModel() override;
    void performSort() override;

private:
    QString m_content;
};

#endif // NOTEMODEL_H
